//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTest
import XCTApodini
@testable import Apodini
@testable import ApodiniOpenAPI
import OpenAPIKit
import ApodiniREST
import ApodiniAuthorization
import ApodiniAuthorizationBasicScheme
import ApodiniAuthorizationJWT

final class OpenAPISecurityMetadataTests: ApodiniTests, InterfaceExporterVisitor {
    struct Token: JWTAuthenticatable {
        var isAdmin: BoolClaim
    }

    struct User: Authenticatable {
        var username: String
        var password: String
    }

    struct UserVerifier: AuthenticationVerifier {
        @Throws(.unauthenticated, reason: "bad password")
        var passwordError

        func initializeAndVerify(for info: (username: String, password: String)) throws -> User {
            guard info.password == "123456" else {
                throw passwordError
            }
            return User(username: info.username, password: info.password)
        }
    }

    struct SomeHandler: Handler {
        @Parameter var myKey: String

        func handle() -> String {
            "Hello World"
        }

        var metadata: Metadata {
            Security(name: "api_key", .apiKey(at: $myKey))
        }
    }

    struct TestWebService: WebService {
        var content: some Component {
            Group("a") {
                Text("Hello A World!")
                    .metadata(Authorize(Token.self, using: BearerAuthenticationScheme(name: "auth_token")))
            }

            Group("b") {
                Text("Hello B World!")
                    .metadata {
                        AuthorizeOptionally(User.self, using: BasicAuthenticationScheme(name: "auth_user"), verifiedBy: UserVerifier())
                    }
            }

            Group("c") {
                SomeHandler()
            }

            Group("d") {
                Text("Hello D World!")
                    .metadata(Security(
                        name: "petstore_auth",
                        .openIdConnect(url: URL(string: "https://example.com/openId")!, scopes: "write:pets", "read:pets")
                    ))
            }

            Group("e") {
                Text("Hello E World!")
                    .metadata(Security(
                        name: "petstore_oauth",
                        .oauth2(
                            flows: .init(implicit: .init(
                                authorizationUrl: URL(string: "https://example.com/api/oauth/dialog")!,
                                scopes: [
                                    "write:pets": "modify pets in your account",
                                    "read:pets": "read your pets"
                                ]
                            )),
                            scopes:
                            "write:pets",
                            "read:pets"
                        )
                    ))
            }

            Group("f") {
                Text("Hello F World!")
                    .metadata {
                        // both are required
                        Security(name: "api_key2", .apiKey(name: "queryKey", location: .query))
                        Security(name: "api_key3", .apiKey(name: "headerKey", location: .header))
                    }
            }
        }

        var configuration: Configuration {
            REST {
                OpenAPI()
            }
        }
    }

    func testOpenAPISecurityDocs() throws {
        var service = TestWebService()
        Apodini.inject(app: app, to: &service)
        Apodini.activate(&service)

        service.start(app: app)

        let openAPIExporter = app.interfaceExporters[1]
        openAPIExporter.accept(self)
    }

    func visit<I: InterfaceExporter>(exporter: I) {
        guard let openAPIExporter = exporter as? OpenAPIInterfaceExporter else {
            fatalError("Test failed due to invalid cast. \(exporter) is not OpenAPI!")
        }

        XCTAssertNoThrow(try assertSecuritySchemes(exporter: openAPIExporter))
    }

    func assertSecuritySchemes(exporter: OpenAPIInterfaceExporter) throws {
        let document = exporter.documentBuilder.build()

        let securitySchemes = document.components.securitySchemes
        let expectedSecuritySchemes: OpenAPIKit.OpenAPI.ComponentDictionary<OpenAPIKit.OpenAPI.SecurityScheme> = [
            "auth_token": .http(scheme: "bearer", bearerFormat: "JWT"),
            "auth_user": .http(scheme: "basic"),
            "api_key": .apiKey(name: "myKey", location: .query),
            "petstore_auth": .openIdConnect(url: URL(string: "https://example.com/openId")!),
            "petstore_oauth": .oauth2(flows: .init(implicit: .init(
                authorizationUrl: URL(string: "https://example.com/api/oauth/dialog")!,
                scopes: [
                    "write:pets": "modify pets in your account",
                    "read:pets": "read your pets"
                ]
            ))),
            "api_key2": .apiKey(name: "queryKey", location: .query),
            "api_key3": .apiKey(name: "headerKey", location: .header)
        ]
        XCTAssertEqual(securitySchemes, expectedSecuritySchemes)


        let aSecurity = try XCTUnwrap(document.paths["v1/a"]?.get).security
        XCTAssertEqual(aSecurity, [[.component(named: "auth_token"): []]])

        let bSecurity = try XCTUnwrap(document.paths["v1/b"]?.get).security
        XCTAssertEqual(bSecurity, [[.component(named: "auth_user"): []], [:]])

        let cSecurity = try XCTUnwrap(document.paths["v1/c"]?.get).security
        XCTAssertEqual(cSecurity, [[.component(named: "api_key"): []]])

        let dSecurity = try XCTUnwrap(document.paths["v1/d"]?.get).security
        XCTAssertEqual(dSecurity, [[.component(named: "petstore_auth"): ["write:pets", "read:pets"]]])

        let eSecurity = try XCTUnwrap(document.paths["v1/e"]?.get).security
        XCTAssertEqual(eSecurity, [[.component(named: "petstore_oauth"): ["write:pets", "read:pets"]]])

        let fSecurity = try XCTUnwrap(document.paths["v1/f"]?.get).security
        XCTAssertEqual(fSecurity, [
            [
                .component(named: "api_key2"): [],
                .component(named: "api_key3"): []
            ]
        ])
    }
}
