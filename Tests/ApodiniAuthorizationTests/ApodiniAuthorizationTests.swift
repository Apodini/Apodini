//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTApodini
import NIOHTTP1
@testable import Apodini
import ApodiniHTTPProtocol
import ApodiniAuthorization
import ApodiniAuthorizationBasicScheme
import ApodiniAuthorizationBearerScheme

class ApodiniAuthorizationTests: XCTApodiniTest {
    struct TestWebService: WebService {
        var content: some Component {
            Group("example") {
                ExampleHandler()
            }
            Group("external") {
                EmptyHandler()
            }.metadata {
                AuthorizeOptionally(
                    MockCredentials<Int>.self,
                    using: BasicAuthenticationScheme(realm: "Realm"),
                    verifiedBy: MockCredentialVerifier(expectedPassword: "123456", state: 3))
            }
            Group("forgottenAuth") {
                EmptyHandler()
            }
            Group("tokenAuth") {
                TokenHandler()
            }
            Group("someError") {
                ErroneousHandler()
            }
            Group("TokenWith2Schemes") {
                HandlerWithOptionalAuth()
            }
        }
    }

    struct EmptyHandler: Handler {
        var user = Authorized(MockCredentials<Int>.self)

        func handle() throws -> String {
            let instance = try user()
            return "Hello World (\(instance.state))"
        }

        var metadata: Metadata {
            OptionalAuthorizationRequirements(MockCredentials<Int>.self) {
                Verify(if: \.state != 0)
            }
        }
    }

    struct ExampleHandler: Handler {
        var user = Authorized(MockCredentials<Int>.self)

        func handle() throws -> String {
            let instance = try user()
            return "Hello World (\(instance.state))"
        }

        var metadata: Metadata {
            Authorize(
                MockCredentials<Int>.self,
                using: BasicAuthenticationScheme(realm: "Realm"),
                verifiedBy: MockCredentialVerifier(expectedPassword: "123456", state: 1))

            Authorize(
                MockCredentials<Int>.self,
                using: BasicAuthenticationScheme(realm: "Realm"),
                verifiedBy: MockCredentialVerifier(expectedPassword: "123456", state: 2),
                skipRequirementsForAuthorized: true) {
                Deny() // this requirements checks are skipped, because they are established above
            }

            Authorize(
                MockCredentials<Int>.self,
                using: BasicAuthenticationScheme(realm: "Realm"),
                verifiedBy: MockCredentialVerifier(expectedPassword: "123456", state: -1)) {
                Allow(if: \.someState)
            }

            AuthorizationRequirements(MockCredentials<Int>.self) {
                Verify(if: \.state == 1)
            }
        }
    }

    struct TokenHandler: Handler {
        @Throws(.unauthenticated, options: .bearerErrorResponse(.init(.invalidToken)))
        var invalidToken

        var token = Authorized(MockToken.self)

        func handle() throws -> String {
            let instance = try token()
            return "Hello World (\(instance.id))"
        }

        var metadata: Metadata {
            Authorize(
                MockToken.self,
                using: BearerAuthenticationScheme(),
                verifiedBy: MockJsonTokenVerifier<MockToken>()) {
                Deny(if: \.id == "0")

                Allow { element in
                    if !element.state {
                        throw invalidToken
                    }
                    return true
                }
            }

            AuthorizationRequirements(MockToken.self) {
                Deny(ifNil: \.optionalState)

                Allow { element in
                    if element.email == "test@example.org" {
                        throw invalidToken
                    }
                    return true
                }
            }
        }
    }

    struct ErroneousHandler: Handler {
        @Throws(.serverError, description: "Some unspecified error")
        var serverError

        func handle() throws -> String {
            // tests that non authorization handler don't get mapped in the authorization scheme
            throw serverError
        }

        var metadata: Metadata {
            Authorize(
                MockToken.self,
                using: BearerAuthenticationScheme(),
                verifiedBy: MockJsonTokenVerifier<MockToken>())
        }
    }

    struct HandlerWithOptionalAuth: Handler {
        var token = Authorized<MockToken>()

        func handle() throws -> String {
            _ = try token()
            return "Hello World"
        }

        var metadata: Metadata {
            AuthorizeOptionally(
                MockToken.self,
                using: BearerAuthenticationScheme(),
                verifiedBy: MockJsonTokenVerifier<MockToken>())

            AuthorizeOptionally(
                MockCredentials<Int>.self,
                using: BasicAuthenticationScheme(realm: "Realm"),
                verifiedBy: MockCredentialVerifier(expectedPassword: "123456", state: -1))
        }
    }

    // swiftlint:disable:next implicitly_unwrapped_optional
    var exporter: MockExporter<EmptyRequest>!
    var exampleHandler = 0
    var emptyHandler = 1
    var forgottenAuthHandler = 2
    var tokenAuthHandler = 3
    var genericHandlerWithError = 4
    var handlerWithTwoOptionalAuths = 5

    override func setUpWithError() throws {
        try super.setUpWithError()

        exporter = MockExporter<EmptyRequest>()
        app.registerExporter(exporter: exporter)

        try TestWebService.start(app: app)
    }

    func runExpectCredentialAuthError(
        _ exporter: MockExporter<EmptyRequest>,
        handler: Int = 0,
        credentials: (username: String, password: String)? = nil,
        expectedWWWAuthenticate: String? = "Basic realm=Realm",
        httpResponse: HTTPResponseStatus = .unauthorized,
        reason: AuthorizationErrorReason
    ) {
        let request: EmptyRequest
        if let credentials = credentials {
            request = EmptyRequest(information: Authorization(.basic(username: credentials.username, password: credentials.password)))
        } else {
            request = EmptyRequest()
        }

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

    func runExpectCredentialSuccess(
        _ exporter: MockExporter<EmptyRequest>,
        handler: Int = 0,
        credentials: (username: String, password: String)? = nil,
        response: String
    ) throws {
        let request: EmptyRequest
        if let credentials = credentials {
            request = EmptyRequest(information: Authorization(.basic(username: credentials.username, password: credentials.password)))
        } else {
            request = EmptyRequest()
        }

        try XCTCheckResponse(
            try XCTUnwrap(
                exporter.request(on: handler, request: request, with: app)
            ),
            content: response
        )
    }


    func runExpectTokenAuthError(
        _ exporter: MockExporter<EmptyRequest>,
        handler: Int = 3,
        token: MockToken? = nil,
        expectedWWWAuthenticate: String? = "Bearer",
        httpResponse: HTTPResponseStatus = .unauthorized,
        reason: AuthorizationErrorReason?
    ) throws {
        let request: EmptyRequest
        if let token = token {
            request = EmptyRequest(information: Authorization(.bearer(try token.toJson())))
        } else {
            request = EmptyRequest()
        }

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

    func runExpectTokenSuccess(
        _ exporter: MockExporter<EmptyRequest>,
        handler: Int = 3,
        token: MockToken?,
        response: String
    ) throws {
        let request: EmptyRequest
        if let token = token {
            request = EmptyRequest(information: Authorization(.bearer(try token.toJson())))
        } else {
            request = EmptyRequest()
        }

        try XCTCheckResponse(
            try XCTUnwrap(
                exporter.request(on: handler, request: request, with: app)
            ),
            content: response
        )
    }


    func testMissingCredentials() {
        runExpectCredentialAuthError(exporter, reason: .authenticationRequired)
    }

    func testMalformedCredentials() {
        let information = AnyHTTPInformation(key: Authorization.header, rawValue: "Basic MALFORMED_BASIC_AUTH")

        XCTAssertThrowsError(
            try exporter
                .requestThrowing(on: exampleHandler, request: EmptyRequest(information: information), with: app)
        ) { (error: Error) in
            // WWWAuthenticate currently doesn't support parsing, therefore we just inspect the raw value!
            XCTAssertEqual(error.apodiniError.information[httpHeader: WWWAuthenticate.header], "Basic realm=Realm")
            XCTAssertEqual(error.apodiniError.option(for: .httpResponseStatus), .unauthorized)
            XCTAssertEqual(error.apodiniError.option(for: .authorizationErrorReason), .invalidAuthenticationRequest)
        }
    }

    func testWrongCredentials() {
        runExpectCredentialAuthError(exporter, credentials: ("username", "wrongPassword"), reason: .failedAuthentication)
    }

    func testSuccessfulAuthorization() throws {
        try runExpectCredentialSuccess(exporter, credentials: ("username", "123456"), response: "Hello World (1)")
    }

    func testComponentDefinedAuthorization() throws {
        try runExpectCredentialSuccess(exporter, handler: emptyHandler, credentials: ("username", "123456"), response: "Hello World (3)")
    }

    func testComponentDefinedAuthorizationFailureInProperty() throws {
        runExpectCredentialAuthError(exporter, handler: emptyHandler, reason: .authenticationRequired)
    }

    func testForgottenAuthorization() throws {
        // currently this produces a runtime failure, as the environment variable isn't injected!
        runExpectCredentialAuthError(exporter, handler: forgottenAuthHandler, expectedWWWAuthenticate: nil, reason: .authenticationRequired)
    }


    func testMissingTokenAuth() throws {
        try runExpectTokenAuthError(exporter, reason: .authenticationRequired)
    }

    func testSuccessfulToken() throws {
        try runExpectTokenSuccess(
            exporter,
            token: MockToken(id: "123456", email: "example@test.org", state: true, optionalState: "asdf"),
            response: "Hello World (123456)")
    }

    func testIdDeniedToken() throws {
        try runExpectTokenAuthError(
            exporter,
            token: MockToken(id: "0", email: "some@test.org", state: true, optionalState: "asdf"),
            reason: .failedAuthorization)
    }

    func testStateDeniedToken() throws {
        try runExpectTokenAuthError(
            exporter,
            token: MockToken(id: "123", email: "some@test.org", state: false, optionalState: "asdf"),
            expectedWWWAuthenticate: "Bearer error=invalid_token",
            reason: .failedAuthorization)
    }

    func testOptionalDeniedToken() throws {
        try runExpectTokenAuthError(
            exporter,
            token: MockToken(id: "123", email: "some@test.org", state: true, optionalState: nil),
            reason: .failedAuthorization)
    }

    func testEmailDeniedToken() throws {
        try runExpectTokenAuthError(
            exporter,
            token: MockToken(id: "123", email: "test@example.org", state: true, optionalState: "asdf"),
            expectedWWWAuthenticate: "Bearer error=invalid_token",
            reason: .failedAuthorization)
    }


    func testGeneralErrorHandling() throws {
        try runExpectTokenAuthError(
            exporter,
            handler: genericHandlerWithError,
            token: MockToken(id: "123", email: "test@example.org", state: true, optionalState: "asdf"),
            expectedWWWAuthenticate: nil,
            httpResponse: .internalServerError,
            reason: nil
        )
    }


    func testResponseWithMultipleChallenges() throws {
        try runExpectTokenAuthError(
            exporter,
            handler: handlerWithTwoOptionalAuths,
            expectedWWWAuthenticate: "Basic realm=Realm, Bearer",
            reason: .authenticationRequired)
    }
}
