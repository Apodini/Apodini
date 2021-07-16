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


@main
struct TestWebService: Apodini.WebService {
    let greeterRelationship = Relationship(name: "greeter")

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
    }
    
    var configuration: Configuration {
        REST {
            OpenAPI(
                outputFormat: .json,
                outputEndpoint: "oas",
                swaggerUiEndpoint: "oas-ui",
                title: "The great TestWebService - presented by Apodini"
            )
        }
        
        GRPC {
            Protobuffer()
        }
        
        WebSocket()
    }
}
