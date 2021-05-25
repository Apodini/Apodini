//
//  Created by Lorena Schlesinger on 28.01.21.
//

import XCTest
@testable import Apodini
@testable import ApodiniVaporSupport
@testable import ApodiniOpenAPI
@testable import ApodiniREST
@_implementationOnly import Yams
@_implementationOnly import OpenAPIKit
import XCTVapor

final class OpenAPIInterfaceExporterTests: ApodiniTests {
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
                _RESTInterfaceExporter {
                    _OpenAPIInterfaceExporter()
                }
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

            guard let htmlFile = Bundle.module.path(forResource: "swagger-ui", ofType: "html"),
                  var html = try? String(contentsOfFile: htmlFile)
                else {
                throw Vapor.Abort(.internalServerError)
            }

            html = html.replacingOccurrences(of: "{{OPEN_API_ENDPOINT_URL}}", with: "/\(OpenAPIConfigurationDefaults.outputEndpoint)")

            XCTAssertEqual(res.body, .init(string: html))
        }
    }

    func testInterfaceExporterConfiguredServing() throws {
        let configuredOutputFormat: OpenAPIOutputFormat = .yaml
        let configuredOutputEndpoint = "/oas"
        let configuredSwaggerUiEndpoint = "/oas-ui"
        
        struct TestWebService: WebService {
            var content: some Component {
                SomeComp()
            }

            var configuration: Configuration {
                _RESTInterfaceExporter(encoder: JSONEncoder(), decoder: JSONDecoder()) {
                    _OpenAPIInterfaceExporter(outputFormat: .yaml,
                                              outputEndpoint: "/oas",
                                              swaggerUiEndpoint: "/oas-ui")
                }
            }
        }

        TestWebService.main(app: app)

        try app.vapor.app.test(.GET, configuredOutputEndpoint) { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertThrowsError(try res.content.decode(OpenAPI.Document.self, using: JSONDecoder()))
        }

        let headers: HTTPHeaders = ["Content-Type": HTTPMediaType.html.serialize()]

        try app.vapor.app.test(.GET, configuredSwaggerUiEndpoint, headers: headers) { res in
            XCTAssertEqual(res.status, .ok)

            guard let htmlFile = Bundle.module.path(forResource: "swagger-ui", ofType: "html"),
                  var html = try? String(contentsOfFile: htmlFile)
                else {
                return XCTFail("Missing Swagger-UI HTML resource.")
            }

            html = html.replacingOccurrences(of: "{{OPEN_API_ENDPOINT_URL}}", with: configuredOutputEndpoint)

            XCTAssertEqual(res.body, .init(string: html))
        }
    }
}
