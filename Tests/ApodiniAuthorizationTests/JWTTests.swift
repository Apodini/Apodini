//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
            Group("optionalAccess") {
                OptionallyAuthorizedHandler()
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
        @Throws(.unauthenticated, options: .bearerErrorResponse(.init(.invalidToken)))
        var unauthenticatedError

        func handle() -> String {
            "Hello World"
        }

        var metadata: Metadata {
            Authorize(ExampleJWTToken.self) {
                Verify(notExpired: \.exp)
                Verify(intendedAudience: \.aud, includes: "ExampleAudience")
                Verify(notBefore: \.nbf)

                Verify(issuer: \.iss, is: "https://other-option.org", "https://example.org")
            }
            Authorize(ExampleJWTToken.self) {
                Deny { element in
                    if element.email == nil {
                        throw unauthenticatedError
                    }
                    return false
                }
            }
        }
    }

    struct OptionallyAuthorizedHandler: Handler {
        var token = Authorized<ExampleJWTToken>()

        func handle() throws -> String {
            guard token.isAuthorized else {
                return "Hello World"
            }

            return "Hello to \(try token().aud.value[0])"
        }

        var metadata: Metadata {
            AuthorizeOptionally(ExampleJWTToken.self)

            OptionalAuthorizationRequirements(ExampleJWTToken.self) {
                Verify(notExpired: \.exp)
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

    // swiftlint:disable:next implicitly_unwrapped_optional
    var exporter: MockExporter<EmptyRequest>!
    var authorizedHandler = 0
    var optionalAuthorizedHandler = 1
    var tokenHandler = 2

    override func setUpWithError() throws {
        try super.setUpWithError()
        exporter = MockExporter<EmptyRequest>()
        app.registerExporter(exporter: exporter)

        TestWebService.start(app: app)
    }

    func runExpectAuthError(
        _ exporter: MockExporter<EmptyRequest>,
        handler: Int = 0,
        token: String? = nil,
        expectedWWWAuthenticate: String = "Bearer",
        httpResponse: HTTPResponseStatus = .unauthorized,
        reason: AuthorizationErrorReason
    ) {
        let request: EmptyRequest
        if let token = token {
            request = EmptyRequest(information: Authorization(.bearer(token)))
        } else {
            request = EmptyRequest()
        }

        // test tokenWithInvalidAudience
        XCTAssertThrowsError(
            try exporter
                .requestThrowing(on: handler, request: request, with: app)
        ) { (error: Error) in
            // WWWAuthenticate currently doesn't support parsing, therefore we just inspect the raw value!
            XCTAssertEqual(error.apodiniError.information[httpHeader: WWWAuthenticate.header], expectedWWWAuthenticate)
            XCTAssertEqual(error.apodiniError.option(for: .httpResponseStatus), httpResponse)
            XCTAssertEqual(error.apodiniError.option(for: .authorizationErrorReason), reason)
        }
    }


    func testJWTWithoutToken() throws {
        // tests that accessing the protected endpoint results in an error
        runExpectAuthError(exporter, reason: .authenticationRequired)
    }

    func testJWTProperToken() throws {
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
    }
    func testJWTOptionalAuthorization() throws {
        try XCTCheckResponse(
            try XCTUnwrap(
                exporter.request(on: optionalAuthorizedHandler, request: EmptyRequest(), with: app)
            ),
            content: "Hello World"
        )

        let requestToken: String = try XCTUnwrap(
            exporter.request(on: tokenHandler, request: EmptyRequest(), with: app, parameters: "test@example.org")
                .typed(String.self)?.content
        )

        try XCTCheckResponse(
            try XCTUnwrap(
                exporter.request(on: optionalAuthorizedHandler, request: EmptyRequest(information: Authorization(.bearer(requestToken))), with: app)
            ),
            content: "Hello to ExampleAudience"
        )
    }

    func testJWTTokenFailingEmailRequirement() throws {
        // request tokenWithoutEmail
        let tokenWithoutEmail: String = try XCTUnwrap(
            exporter.request(on: tokenHandler, request: EmptyRequest(), with: app)
                .typed(String.self)?.content
        )

        // test fullyCorrectToken
        runExpectAuthError(exporter, token: tokenWithoutEmail, expectedWWWAuthenticate: "Bearer error=invalid_token", reason: .failedAuthorization)
    }

    func testJWTFailingAudienceClaim() throws {
        // request tokenWithInvalidAudience
        let tokenInvalidAudience: String = try XCTUnwrap(
            exporter.request(on: tokenHandler, request: EmptyRequest(), with: app, parameters: "test@example.org", "SomeOtherAudience")
                .typed(String.self)?.content
        )

        // test tokenWithInvalidAudience
        runExpectAuthError(exporter, token: tokenInvalidAudience, reason: .failedAuthorization)
    }

    func testJWTFailingExpirationClaim() throws {
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
    }

    func testJWTFailingNotBeforeClaim() throws {
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
    }

    func testJWTFailingSignatureCheck() throws {
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
}
