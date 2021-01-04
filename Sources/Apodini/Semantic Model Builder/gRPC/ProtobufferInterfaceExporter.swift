//
//  File.swift
//  
//
//  Created by Nityananda on 03.12.20.
//

@_implementationOnly import class Vapor.Application
import ProtobufferBuilder

extension Never: ExporterRequest {}

class ProtobufferInterfaceExporter: InterfaceExporter {
    typealias ExporterRequest = Never
    
    private let app: Vapor.Application
    private let builder: ProtobufferBuilder
    
    required init(_ app: Application) {
        self.app = app
        self.builder = ProtobufferBuilder()
        
        self.app.get("apodini", "proto") { _ in
            self.builder.description
        }
    }
    
    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        let serviceName = endpoint.serviceName
        let methodName = endpoint.methodName
        let inputType: Any.Type = endpoint.parameters.first?.propertyType ?? Void.self
        
        do {
            try builder.addService(
                serviceName: serviceName,
                methodName: methodName,
                inputType: inputType,
                returnType: endpoint.responseType
            )
        } catch {
            app.logger.error("\(error)")
        }
    }
    
    func retrieveParameter<Type>(_ parameter: EndpointParameter<Type>, for request: Never) throws -> Type?? where Type: Decodable, Type: Encodable {
        nil
    }
}
