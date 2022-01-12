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


@main
struct TestWebService: Apodini.WebService {
    private static let greeterRelationship = Relationship(name: "greeter")

    @Argument(help: "Endpoint to expose OpenAPI specification")
    var openApiEndpoint: String = "oas"
    
    var content: some Component {
        // Hello World! 👋
        Text("Hello World! 👋")
            .response(EmojiTransformer(emojis: "🎉"))
            .pattern(.requestResponse)

        // Bigger Subsystems:
        AuctionComponent()
        GreetComponent(greeterRelationship: TestWebService.greeterRelationship)
        RandomComponent(greeterRelationship: TestWebService.greeterRelationship)
        SwiftComponent()
        UserComponent(greeterRelationship: TestWebService.greeterRelationship)
        WeatherComponent()
    }
    
    var configuration: Configuration {
        HTTP(rootPath: "http")
        
        REST {
            OpenAPI(
                outputFormat: .json,
                outputEndpoint: openApiEndpoint,
                swaggerUiEndpoint: openApiEndpoint + "-ui",
                title: "The great TestWebService - presented by Apodini"
            )
        }
        
        HTTPConfiguration(tlsConfigurationBuilder: .init(
            certificatePath: "/Users/lukas/Documents/apodini certs/localhost.cer.pem",
            keyPath: "/Users/lukas/Documents/apodini certs/localhost.key.pem"
        ))
        
        WebSocket()
        
        Migrator()
        
        GRPC(packageName: "de.lukaskollmer", serviceName: "TestWebService")
        
        // Tracing configuration for an OpenTelemetry backend with default configuration options
        TracingConfiguration(
            .defaultOpenTelemetry(serviceName: "TestWebService")
        )
    }
}
