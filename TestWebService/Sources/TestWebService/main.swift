//
//  TestWebService.swift
//
//
//  Created by Paul Schmiedmayer on 7/6/20.
//

import Apodini


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
        OpenAPIConfiguration(
            outputFormat: .json,
            outputEndpoint: "oas",
            swaggerUiEndpoint: "oas-ui",
            title: "The great TestWebService - presented by Apodini"
        )
        HTTP2Configuration()
            .certificate("/Users/moritzschull/Desktop/cert/cert.pem")
            .key("/Users/moritzschull/Desktop/cert/key.pem")
    }
}

try TestWebService.main()
