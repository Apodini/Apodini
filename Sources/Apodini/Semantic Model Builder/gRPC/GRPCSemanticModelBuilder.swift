//
//  GRPCSemanticModelBuilder.swift
//
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Vapor
import ProtobufferCoding

class GRPCSemanticModelBuilder: SemanticModelBuilder {
    override func register<C: Component>(component: C, withContext context: Context) {
        let handler: (Vapor.Request) -> EventLoopFuture<Vapor.Response> =
            context.createClientStreamRequestHandler(withComponent: component, using: self)
        app.on(.POST, "testservice", "method", body: .stream, use: handler)
    }

    override func decode<T: Decodable>(_ type: T.Type, from request: Vapor.Request) throws -> T? {
        // do decoding fun
        return nil
    }
}
