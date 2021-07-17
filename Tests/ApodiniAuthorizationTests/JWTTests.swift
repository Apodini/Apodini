//
// Created by Andreas Bauer on 15.07.21.
//

@testable import Apodini
import ApodiniAuthorizationJWT
import ApodiniHTTPProtocol
import ApodiniVaporSupport
import XCTApodini
import NIOHTTP1

class JWTTests: XCTApodiniTest {
    struct TestWebService: WebService {
        var content: some Component {
            Group("access") {
                AuthorizedHandler()
            }
            Group("token") {
                TokenCreationHandler()
            }
        }

        var configuration: Configuration {
            JWTSigner(.hs256(key: "secretKey"))
        }
    }

    struct AuthorizedHandler: Handler {
        func handle() -> String {
            "Hello World"
        }

        var metadata: Metadata {
            Authorize(ExampleJWTToken.self) {
                Verify(notExpired: \.exp)
                Verify(intendedAudience: \.aud, includes: "ExampleAudience")
                Verify(notBefore: \.nbf)

                Verify(issuer: \.iss, is: "https://other-option.org", "https://example.org")

                Deny(ifNil: \.email)
            }
        }
    }

    struct TokenCreationHandler: Handler {
        @Environment(\.jwtSigners)
        var signers

        @Parameter
        var email: String?
        @Parameter
        var audience = "ExampleAudience"
        @Parameter
        var expiration = Date().addingTimeInterval(60 * 60) // 1h in the future
        @Parameter
        var notBefore = Date().addingTimeInterval(-1 * 60 * 60) // 1h in the past

        func handle() throws -> String {
            let payload = ExampleJWTToken(
                exp: .init(value: expiration),
                nbf: .init(value: notBefore),
                aud: .init(value: audience),
                iss: "https://example.org",
                email: email
            )
            
            return try signers.sign(payload)
        }
    }

    struct ExampleJWTToken: JWTAuthenticatable {
        var exp: ExpirationClaim
        var nbf: NotBeforeClaim
        var aud: AudienceClaim
        var iss: IssuerClaim

        var email: String?
    }

    // TODO maybe split up into multiple test cases?
    func testJWTEndToEnd() throws {
        let exporter = MockExporter<EmptyRequest>()
        app.registerExporter(exporter: exporter)

        TestWebService.start(app: app)

        let authorizedHandler = 0
        let tokenHandler = 1

        // tests that accessing the protected endpoint results in an error
        XCTAssertThrowsError(try exporter.requestThrowing(on: authorizedHandler, request: EmptyRequest(), with: app)) { (error: Error) in
            // WWWAuthenticate currently doesn't support parsing, therefore we just inspect the raw value!
            XCTAssertEqual(error.apodiniError.information[httpHeader: WWWAuthenticate.header], "Bearer")
            XCTAssertEqual(error.apodiniError.option(for: .httpResponseStatus), .unauthorized)
            XCTAssertEqual(error.apodiniError.option(for: .authorizationErrorReason), .authenticationRequired)
        }


        // request fullyCorrectToken
        let fullyCorrectToken: String = try XCTUnwrap(
            exporter.request(on: tokenHandler, request: EmptyRequest(), with: app, parameters: "test@example.org")
                .typed(String.self)?.content
        )

        // test fullyCorrectToken
        try XCTCheckResponse(
            try XCTUnwrap(
                exporter.request(on: authorizedHandler, request: EmptyRequest(information: Authorization(.bearer(fullyCorrectToken))), with: app)
            ),
            content: "Hello World"
        )


        // request tokenWithoutEmail
        let tokenWithoutEmail: String = try XCTUnwrap(
            exporter.request(on: tokenHandler, request: EmptyRequest(), with: app)
                .typed(String.self)?.content
        )

        // test fullyCorrectToken
        runExpectAuthError(exporter, token: tokenWithoutEmail, reason: .failedAuthorization)


        // request tokenWithInvalidAudience
        let tokenInvalidAudience: String = try XCTUnwrap(
            exporter.request(on: tokenHandler, request: EmptyRequest(), with: app, parameters: "test@example.org", "SomeOtherAudience")
                .typed(String.self)?.content
        )

        // test tokenWithInvalidAudience
        runExpectAuthError(exporter, token: tokenInvalidAudience, reason: .failedAuthorization)


        // request tokenExpired
        let tokenExpired: String = try XCTUnwrap(
            exporter.request(
                    on: tokenHandler,
                    request: EmptyRequest(),
                    with: app,
                    parameters: "test@example.org",
                    "ExampleAudience",
                    Date().addingTimeInterval(-1 * 60 * 60)) // expiration: 1h in the past
                .typed(String.self)?.content
        )

        // test tokenExpired
        runExpectAuthError(exporter, token: tokenExpired, reason: .failedAuthorization)

        // request tokenNotYetValid
        let tokenNotYetValid: String = try XCTUnwrap(
            exporter.request(
                    on: tokenHandler,
                    request: EmptyRequest(),
                    with: app,
                    parameters: "test@example.org",
                    "ExampleAudience",
                    Date().addingTimeInterval(60 * 60), // expiration: 1h in the future
                    Date().addingTimeInterval(60 * 30)) // notBefore: 30m in the future
                .typed(String.self)?.content
        )

        // test tokenNotYetValid
        runExpectAuthError(exporter, token: tokenNotYetValid, reason: .failedAuthorization)


        // test manipulated token with invalid signature
        runExpectAuthError(
            exporter,
            token: """
                   eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.\
                   eyJleHAiOjE2MjYzNzM2NzMuMjQyNzQyLCJuYmYiOjE2MjYzNjY0NzMuMjQyNzQ1OSwiZ\
                   W1haWwiOiJ0ZXN0QGV4YW1wbGUub3JnIiwiYXVkIjoiRXhhbXBsZUF1ZGllbmNlIn0.\
                   aYTxbySIcILhdLdTxKqcsvt51NvwoIjyh82Eo8bVmdE
                   """,
            reason: .failedAuthentication)
    }

    func runExpectAuthError(
        _ exporter: MockExporter<EmptyRequest>,
        token: String,
        httpResponse: HTTPResponseStatus = .unauthorized,
        reason: AuthorizationErrorReason
    ) {
        // test tokenWithInvalidAudience
        XCTAssertThrowsError(
            try exporter
                .requestThrowing(on: 0, request: EmptyRequest(information: Authorization(.bearer(token))), with: app)
        ) { (error: Error) in
            // WWWAuthenticate currently doesn't support parsing, therefore we just inspect the raw value!
            XCTAssertEqual(error.apodiniError.information[httpHeader: WWWAuthenticate.header], "Bearer")
            XCTAssertEqual(error.apodiniError.option(for: .httpResponseStatus), httpResponse)
            XCTAssertEqual(error.apodiniError.option(for: .authorizationErrorReason), reason)
        }
    }
}
