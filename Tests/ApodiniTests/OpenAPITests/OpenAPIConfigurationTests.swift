//
//  Created by Lorena Schlesinger on 28.01.21.
//

import XCTest
@testable import Apodini
@testable import ApodiniOpenAPI
@testable import ApodiniREST

final class OpenAPIConfigurationTests: ApodiniTests {
    func testBuildDocumentWithConfiguration() throws {
        let configuredOutputFormat: OpenAPIOutputFormat = .yaml
        let configuredOutputEndpoint = "oas"
        let configuredSwaggerUiEndpoint = "oas-ui"
        let configuredTitle = "The great TestWebService - presented by Apodini"
        let configuredParentRESTConfiguration = RESTExporterConfiguration(encoder: JSONEncoder(), decoder: JSONDecoder())

        let openAPIConfiguration = OpenAPIExporterConfiguration(
            parentConfiguration: configuredParentRESTConfiguration,
            outputFormat: configuredOutputFormat,
            outputEndpoint: configuredOutputEndpoint,
            swaggerUiEndpoint: configuredSwaggerUiEndpoint,
            title: configuredTitle
        )
        
        let openAPIExporter = OpenAPIInterfaceExporter(app, openAPIConfiguration)
        //openAPIConfiguration.configure(app)

        //let storage = try XCTUnwrap(app.storage.get(OpenAPIStorageKey.self))

        XCTAssertEqual(openAPIExporter.exporterConfiguration.outputFormat, configuredOutputFormat)
        // Since given as relative paths, `outputEndpoint` was prefixed.
        XCTAssertNotEqual(openAPIExporter.exporterConfiguration.outputEndpoint, "\(configuredOutputEndpoint)")
        XCTAssertEqual(openAPIExporter.exporterConfiguration.outputEndpoint, "\(openAPIConfiguration.outputEndpoint)")
        // Since given as relative paths, `swaggerUiEndpoint` was prefixed.
        XCTAssertNotEqual(openAPIExporter.exporterConfiguration.swaggerUiEndpoint, "\(configuredSwaggerUiEndpoint)")
        XCTAssertEqual(openAPIExporter.exporterConfiguration.swaggerUiEndpoint, "\(openAPIConfiguration.swaggerUiEndpoint)")
        XCTAssertEqual(openAPIExporter.exporterConfiguration.title, configuredTitle)
        // Just simple assertions since it's very tricky to compare encoders
        XCTAssertNotNil(openAPIExporter.exporterConfiguration.parentConfiguration)
        XCTAssertTrue(openAPIExporter.exporterConfiguration.parentConfiguration is RESTExporterConfiguration)
        XCTAssertNoThrow(openAPIExporter.exporterConfiguration.parentConfiguration as! RESTExporterConfiguration)
        let parentConfiguration = openAPIExporter.exporterConfiguration.parentConfiguration as! RESTExporterConfiguration
        XCTAssertNotNil(parentConfiguration.encoder)
        XCTAssertNotNil(parentConfiguration.decoder)
        XCTAssertTrue(parentConfiguration.encoder is JSONEncoder)
        XCTAssertTrue(parentConfiguration.decoder is JSONDecoder)
    }

    func testBuildDocumentWithDefaultConfiguration() throws {
        let openAPIConfiguration = OpenAPIExporterConfiguration()
        let openAPIExporter = OpenAPIInterfaceExporter(app, openAPIConfiguration)

        XCTAssertEqual(openAPIExporter.exporterConfiguration.outputFormat, OpenAPIConfigurationDefaults.outputFormat)
        XCTAssertEqual(openAPIExporter.exporterConfiguration.outputEndpoint, "/\(OpenAPIConfigurationDefaults.outputEndpoint)")
        XCTAssertEqual(openAPIExporter.exporterConfiguration.swaggerUiEndpoint, "/\(OpenAPIConfigurationDefaults.swaggerUiEndpoint)")
        XCTAssertNil(openAPIExporter.exporterConfiguration.title)
        // Just simple assertions since it's very tricky to compare encoders
        XCTAssertNotNil(openAPIExporter.exporterConfiguration.parentConfiguration)
    }
}
