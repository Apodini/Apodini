//
//  Created by Lorena Schlesinger on 28.01.21.
//

import XCTest
@testable import Apodini
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
                OpenAPIConfiguration()
            }
        }
    
        TestWebService.main(app: app)
    
        try app.vapor.app.test(.GET, "\(OpenAPIConfigurationDefaults.outputEndpoint)") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertNoThrow(try res.content.decode(OpenAPI.Document.self, using: JSONDecoder()))
        }
        
        let headers: HTTPHeaders = ["Content-Type": HTTPMediaType.html.serialize()]
        
        try app.vapor.app.test(.GET, "\(OpenAPIConfigurationDefaults.swaggerUiEndpoint)", headers: headers) { res in
            XCTAssertEqual(res.status, .ok)
            
            guard let htmlFile = Bundle.module.path(forResource: "swagger-ui", ofType: "html"),
                  var html = try? String(contentsOfFile: htmlFile)
            else {
                throw Vapor.Abort(.internalServerError)
            }
            
            html = html.replacingOccurrences(of: "{{OPEN_API_ENDPOINT_URL}}", with: OpenAPIConfigurationDefaults.outputEndpoint)

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
            }
        }
    
        TestWebService.main(app: app)
    
        try app.vapor.app.test(.GET, "oas") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertThrowsError(try res.content.decode(OpenAPI.Document.self, using: JSONDecoder()))
        }
        
        let headers: HTTPHeaders = ["Content-Type": HTTPMediaType.html.serialize()]
        
        try app.vapor.app.test(.GET, "oas-ui", headers: headers) { res in
            XCTAssertEqual(res.status, .ok)
            
            XCTAssertNil(Bundle.module.path(forResource: "swagger-ui-wrong", ofType: "html"))
            
            guard let htmlFile = Bundle.module.path(forResource: "swagger-ui", ofType: "html"),
                  var html = try? String(contentsOfFile: htmlFile)
            else {
                throw Vapor.Abort(.internalServerError)
            }
            
            html = html.replacingOccurrences(of: "{{OPEN_API_ENDPOINT_URL}}", with: "oas")

            XCTAssertEqual(res.body, .init(string: html))
        }
    }
}
