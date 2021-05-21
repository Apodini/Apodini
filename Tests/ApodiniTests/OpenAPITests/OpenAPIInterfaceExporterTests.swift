//
//  Created by Lorena Schlesinger on 28.01.21.
//

import XCTest
@testable import Apodini
@testable import ApodiniVaporSupport
@testable import ApodiniOpenAPI
@_implementationOnly import Yams
@_implementationOnly import OpenAPIKit
import XCTVapor

final class OpenAPIInterfaceExporterTests: XCTApodiniDatabaseBirdTest {
    struct SomeComp: Handler {
        func handle() -> String {
            "Test"
        }
    }

    func testInterfaceExporterDefaultServing() throws {
        struct TestWebService: WebService {
            var content: some Component {
                SomeComp()
            }

            var configuration: Configuration {
                OpenAPIConfiguration()
                ExporterConfiguration()
                    .exporter(OpenAPIInterfaceExporter.self)
            }
        }

        TestWebService.main(app: app)

        try app.vapor.app.test(.GET, "\(OpenAPIConfigurationDefaults.outputEndpoint)") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertNoThrow(try res.content.decode(OpenAPI.Document.self, using: JSONDecoder()))
        }

        let headers: HTTPHeaders = ["Content-Type": HTTPMediaType.html.serialize()]

        try app.vapor.app.test(.GET, "/\(OpenAPIConfigurationDefaults.swaggerUiEndpoint)", headers: headers) { res in
            XCTAssertEqual(res.status, .ok)

            guard let htmlFile = Bundle.apodiniOpenAPIResources.path(forResource: "swagger-ui", ofType: "html"),
                  var html = try? String(contentsOfFile: htmlFile)
                else {
                throw Vapor.Abort(.internalServerError)
            }

            html = html.replacingOccurrences(of: "{{OPEN_API_ENDPOINT_URL}}", with: "/\(OpenAPIConfigurationDefaults.outputEndpoint)")

            XCTAssertEqual(res.body, .init(string: html))
        }
    }

    func testInterfaceExporterConfiguredServing() throws {
        struct TestWebService: WebService {
            var content: some Component {
                SomeComp()
            }

            var configuration: Configuration {
                OpenAPIConfiguration(
                    outputFormat: .yaml,
                    outputEndpoint: "oas",
                    swaggerUiEndpoint: "oas-ui"
                )
                ExporterConfiguration()
                .exporter(OpenAPIInterfaceExporter.self)
            }
        }

        TestWebService.main(app: app)
        
        let storage = try XCTUnwrap(app.storage.get(OpenAPIStorageKey.self))

        try app.vapor.app.test(.GET, storage.configuration.outputEndpoint) { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertThrowsError(try res.content.decode(OpenAPI.Document.self, using: JSONDecoder()))
        }

        let headers: HTTPHeaders = ["Content-Type": HTTPMediaType.html.serialize()]

        try app.vapor.app.test(.GET, storage.configuration.swaggerUiEndpoint, headers: headers) { res in
            XCTAssertEqual(res.status, .ok)

            guard let htmlFile = Bundle.apodiniOpenAPIResources.path(forResource: "swagger-ui", ofType: "html"),
                  var html = try? String(contentsOfFile: htmlFile)
                else {
                return XCTFail("Missing Swagger-UI HTML resource.")
            }

            html = html.replacingOccurrences(of: "{{OPEN_API_ENDPOINT_URL}}", with: storage.configuration.outputEndpoint)

            XCTAssertEqual(res.body, .init(string: html))
        }
    }
}
