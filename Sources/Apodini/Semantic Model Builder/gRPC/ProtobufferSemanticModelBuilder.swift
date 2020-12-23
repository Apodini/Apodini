//
//  File.swift
//  
//
//  Created by Nityananda on 03.12.20.
//

@_implementationOnly import Vapor
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
        let pathComponents = context.get(valueFor: PathComponentContextKey.self)
        let serviceName = StringPathBuilder(pathComponents, delimiter: "")
            .build()
            .capitalized
        
        do {
            try builder.addService(
                serviceName: serviceName,
                componentType: C.self,
                returnType: C.Response.self
            )
        } catch {
            app.logger.error("\(error)")
        }
    }
}
