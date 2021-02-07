//
//  Created by Lorena Schlesinger on 28.01.21.
//

import XCTest
@testable import Apodini
@testable import ApodiniOpenAPI

final class OpenAPIConfigurationTests: ApodiniTests {
    func testBuildDocumentWithConfiguration() throws {
        let configuredOutputFormat: OpenAPIOutputFormat = .yaml
        let configuredOutputEndpoint = "oas"
        let configuredSwaggerUiEndpoint = "oas-ui"
        let configuredTitle = "The great TestWebService - presented by Apodini"

        let openAPIConfiguration = OpenAPIConfiguration(
            outputFormat: configuredOutputFormat,
            outputEndpoint: configuredOutputEndpoint,
            swaggerUiEndpoint: configuredSwaggerUiEndpoint,
            title: configuredTitle
        )
        openAPIConfiguration.configure(app)

        let storage = try XCTUnwrap(app.storage.get(OpenAPIStorageKey.self))

        XCTAssertEqual(storage.configuration.outputFormat, configuredOutputFormat)
        // Since given as relative paths, `outputEndpoint` was prefixed.
        XCTAssertNotEqual(storage.configuration.outputEndpoint, "\(configuredOutputEndpoint)")
        XCTAssertEqual(storage.configuration.outputEndpoint, "\(openAPIConfiguration.outputEndpoint)")
        // Since given as relative paths, `swaggerUiEndpoint` was prefixed.
        XCTAssertNotEqual(storage.configuration.swaggerUiEndpoint, "\(configuredSwaggerUiEndpoint)")
        XCTAssertEqual(storage.configuration.swaggerUiEndpoint, "\(openAPIConfiguration.swaggerUiEndpoint)")
        XCTAssertEqual(storage.configuration.title, configuredTitle)
    }

    func testBuildDocumentWithDefaultConfiguration() throws {
        OpenAPIConfiguration()
            .configure(app)

        let storage = try XCTUnwrap(app.storage.get(OpenAPIStorageKey.self))

        XCTAssertEqual(storage.configuration.outputFormat, OpenAPIConfigurationDefaults.outputFormat)
        XCTAssertEqual(storage.configuration.outputEndpoint, "/\(OpenAPIConfigurationDefaults.outputEndpoint)")
        XCTAssertEqual(storage.configuration.swaggerUiEndpoint, "/\(OpenAPIConfigurationDefaults.swaggerUiEndpoint)")
        XCTAssertNil(storage.configuration.title)
    }
}
