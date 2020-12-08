//
//  File.swift
//  
//
//  Created by Nityananda on 03.12.20.
//

import Vapor
import ProtobufferBuilder

class ProtobufferSemanticModelBuilder: SemanticModelBuilder {
    private let builder = ProtobufferBuilder()
    
    override init(_ app: Application) {
        super.init(app)
        
        self.app.get("apodini", "proto") { req in
            self.builder.description
        }
    }
    
    override func register<C>(component: C, withContext context: Context) where C : Component {
        print(Result(catching: { try builder.addService(of: C.self) }))
        print(Result(catching: { try builder.addMessage(of: C.Response.self) }))
    }
}
