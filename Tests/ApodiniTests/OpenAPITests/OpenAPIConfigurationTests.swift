//
//  Created by Lorena Schlesinger on 28.01.21.
//

import XCTest
@testable import Apodini

final class OpenAPIConfigurationTests: ApodiniTests {
    func testBuildDocumentWithConfiguration() {
        let configuredOutputFormat: OpenAPIOutputFormat = .yaml
        let configuredOutputEndpoint = "oas"
        let configuredSwaggerUiEndpoint = "oas-ui"
        let configuredTitle = "The great TestWebService - presented by Apodini"
        
        OpenAPIConfiguration(
            outputFormat: configuredOutputFormat,
            outputEndpoint: configuredOutputEndpoint,
            swaggerUiEndpoint: configuredSwaggerUiEndpoint,
            title: configuredTitle)
            .configure(app)
        
        let storage = app.storage.get(OpenAPIStorageKey.self)
        
        XCTAssertNotNil(storage)
        XCTAssertEqual(storage?.configuration.outputFormat, configuredOutputFormat)
        XCTAssertEqual(storage?.configuration.outputEndpoint, configuredOutputEndpoint)
        XCTAssertEqual(storage?.configuration.swaggerUiEndpoint, configuredSwaggerUiEndpoint)
        XCTAssertEqual(storage?.configuration.title, configuredTitle)
    }
    
    func testBuildDocumentWithDefaultConfiguration() {
        OpenAPIConfiguration()
            .configure(app)
        
        let storage = app.storage.get(OpenAPIStorageKey.self)
        
        XCTAssertNotNil(storage)
        XCTAssertEqual(storage?.configuration.outputFormat, OpenAPIConfigurationDefaults.defaultOutputFormat)
        XCTAssertEqual(storage?.configuration.outputEndpoint, OpenAPIConfigurationDefaults.defaultOutputEndpoint)
        XCTAssertEqual(storage?.configuration.swaggerUiEndpoint, OpenAPIConfigurationDefaults.defaultSwaggerUiEndpoint)
        XCTAssertNil(storage?.configuration.title)
    }
}
