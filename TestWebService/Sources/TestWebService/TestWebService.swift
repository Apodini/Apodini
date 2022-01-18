//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import ApodiniHTTP
import ApodiniREST
import ApodiniOpenAPI
import ApodiniWebSocket
import ApodiniMigration
import ApodiniObserve
import ApodiniObserveOpenTelemetry
import ArgumentParser
import Tracing
import ApodiniGRPC
import Foundation
import ApodiniGraphQL


@main
struct TestWebService: Apodini.WebService {
    private static let greeterRelationship = Relationship(name: "greeter")
    
    @Argument(help: "Endpoint to expose OpenAPI specification")
    var openApiEndpoint: String = "oas"
    
    @Option(help: "The TestWebService's HTTPS config. Omit to disable HTTPS, specify 'builtin' to use buitin self-signed certificates, or pass a path to a custom certificate and key.") // swiftlint:disable:this line_length
    var httpsConfig: HTTPSConfig = .none
    
    @Option(help: "Port")
    var port: Int?
    
    var content: some Component {
        // Hello World! 👋
        Text("Hello World! 👋")
            .response(EmojiTransformer(emojis: "🎉"))
            .pattern(.requestResponse)
            .endpointName("root")

        // Bigger Subsystems:
        AuctionComponent()
        GreetComponent(greeterRelationship: TestWebService.greeterRelationship)
        RandomComponent(greeterRelationship: TestWebService.greeterRelationship)
        SwiftComponent()
        UserComponent(greeterRelationship: TestWebService.greeterRelationship)
        WeatherComponent()
    }
    
    var configuration: Configuration {
        switch httpsConfig {
        case .none:
            HTTPConfiguration(
                hostname: .init(address: "localhost", port: port),
                bindAddress: .interface("0.0.0.0", port: port)
            )
        case .builtinSelfSignedCertificate:
            HTTPConfiguration(
                hostname: .init(address: "localhost", port: port),
                bindAddress: .interface("0.0.0.0", port: port),
                tlsConfiguration: .init(
                    certificatePath: Bundle.module.url(forResource: "localhost.cer", withExtension: "pem")!.path,
                    keyPath: Bundle.module.url(forResource: "localhost.key", withExtension: "pem")!.path
                )
            )
        case let .custom(certPath, keyPath):
            HTTPConfiguration(
                hostname: .init(address: "localhost", port: port),
                bindAddress: .interface("0.0.0.0", port: port),
                tlsConfiguration: .init(certificatePath: certPath, keyPath: keyPath)
            )
        }
        
        HTTP(rootPath: "http")
        
        REST {
            OpenAPI(
                outputFormat: .json,
                outputEndpoint: openApiEndpoint,
                swaggerUiEndpoint: openApiEndpoint + "-ui",
                title: "The great TestWebService - presented by Apodini"
            )
        }
        
        WebSocket()
        
        Migrator()
        
        GRPC(packageName: "org.apodini", serviceName: "TestWebService")
            .skip(if: !.isHTTPSEnabled)
        
        GraphQL(enableGraphiQL: true)
        
        // Tracing configuration for an OpenTelemetry backend with default configuration options
        TracingConfiguration(
            .defaultOpenTelemetry(serviceName: "TestWebService")
        )
    }
}


// MARK: HTTPS Utilities

enum HTTPSConfig: Decodable, ExpressibleByArgument {
    case none
    case builtinSelfSignedCertificate
    case custom(certPath: String, keyPath: String)
    
    init?(argument: String) {
        switch argument {
        case "none":
            self = .none
        case "builtin":
            self = .builtinSelfSignedCertificate
        default:
            guard case let components = argument.split(separator: ","), components.count == 2 else {
                return nil
            }
            self = .custom(certPath: String(components[0]), keyPath: String(components[1]))
        }
    }
    
    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        if let value = Self(argument: rawValue) {
            self = value
        } else {
            throw NSError(domain: "org.apodini.TestWebService", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Invalid input for HTTPS config option: '\(rawValue)'"
            ])
        }
    }
}
