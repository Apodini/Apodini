//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import ApodiniREST
import ApodiniGRPC
import ApodiniProtobuffer
import ApodiniOpenAPI
import ApodiniWebSocket
import ApodiniMigration
import ArgumentParser


@main
struct TestWebService: Apodini.WebService {
    let greeterRelationship = Relationship(name: "greeter")

    @Argument(help: "Endpoint to expose OpenAPI specification")
    var openApiEndpoint: String = "oas"
    
    var content: some Component {
        // Hello World! 👋
        Text("Hello World! 👋")
            .response(EmojiTransformer(emojis: "🎉"))

        // Bigger Subsystems:
        AuctionComponent()
        GreetComponent(greeterRelationship: greeterRelationship)
        RandomComponent(greeterRelationship: greeterRelationship)
        SwiftComponent()
        UserComponent(greeterRelationship: greeterRelationship)
        WeatherComponent()
    }
    
    var configuration: Configuration {
        HTTPConfiguration()
        
        REST {
            OpenAPI(
                outputFormat: .json,
                outputEndpoint: openApiEndpoint,
                swaggerUiEndpoint: "oas-ui",
                title: "The great TestWebService - presented by Apodini"
            )
        }
        
        GRPC {
            Protobuffer()
        }
        
        WebSocket()
        
        Migrator()
    }
}
