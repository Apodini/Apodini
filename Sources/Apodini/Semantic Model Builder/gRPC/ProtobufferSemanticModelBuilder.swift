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
    
    required override init(_ app: Application) {
        super.init(app)
        
        self.app.get("apodini", "proto") { req in
            self.builder.description
        }
    }
}

extension ProtobufferSemanticModelBuilder: InterfaceExporter {
    func export(_ endpoint: Endpoint) {
        let pathComponents = endpoint.context.get(valueFor: PathComponentContextKey.self)
        let serviceName = StringPathBuilder(pathComponents, delimiter: "")
            .build()
            .capitalized
        let inputType: Any.Type = endpoint.parameters.first?.contentType ?? Void.self
        
        do {
            try builder.addService(
                serviceName: serviceName,
                inputType: inputType,
                returnType: endpoint.responseType
            )
        } catch {
            app.logger.error("\(error)")
        }
    }
}
