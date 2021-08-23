//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import XCTest
@testable import Apodini
import ApodiniREST
@testable import ApodiniOpenAPI
import OpenAPIKit

final class OpenAPIWebServiceMetadataTests: ApodiniTests, InterfaceExporterVisitor {
    struct ExampleWebService: WebService {
        var content: some Component {
            EmptyComponent()
        }

        var metadata: Metadata {
            Description("The description")

            Version(major: 2, minor: 3)

            Contact(name: "Example Company", url: URL(string: "https://example.com")!, email: "some@example.com")

            License(name: "MIT", url: URL(string: "https://mit-license.org")!)

            TermsOfService(url: URL(string: "https://example.com")!)

            TagDescriptions {
                TagDescription(name: "authentication", description: "Authentication endpoints.")
                TagDescription(name: "user", description: "User endpoints.")
            }

            ExternalDocumentation(
                description: """
                             Further documentation for the `ExampleWebService` is available here.
                             """,
                url: URL(string: "https://example.com")!
            )
        }

        var configuration: Configuration {
            REST {
                ApodiniOpenAPI.OpenAPI(title: "ExampleWebService")
            }
        }
    }

    func testWebServiceMetadata() throws {
        let modelBuilder = SemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)

        var service = ExampleWebService()
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

        let expectedDocument = OpenAPIKit.OpenAPI.Document(
            info: .init(
                title: "ExampleWebService",
                description: "The description",
                termsOfService: URL(string: "https://example.com")!,
                contact: .init(
                    name: "Example Company",
                    url: URL(string: "https://example.com"),
                    email: "some@example.com"
                ),
                license: .init(
                    name: "MIT",
                    url: URL(string: "https://mit-license.org")!
                ),
                version: "2.3.0"
            ),
            servers: [.init(url: URL(string: "http://127.0.0.1:8080")!)],
            paths: [:],
            components: .init(),
            tags: [
                .init(name: "authentication", description: "Authentication endpoints."),
                .init(name: "user", description: "User endpoints.")
            ],
            externalDocs: .init(
                description: "Further documentation for the `ExampleWebService` is available here.",
                url: URL(string: "https://example.com")!
            )
        )

        XCTAssertEqual(openAPIExporter.documentBuilder.build(), expectedDocument)
    }
}
