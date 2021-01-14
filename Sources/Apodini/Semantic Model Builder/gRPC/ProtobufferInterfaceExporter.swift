//
//  File.swift
//  
//
//  Created by Nityananda on 03.12.20.
//

@_implementationOnly import class Vapor.Application

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
        do {
            try builder.analyze(endpoint: endpoint)
        } catch {
            app.logger.error("\(error)")
        }
    }
    
    func retrieveParameter<Type>(_ parameter: EndpointParameter<Type>, for request: Never) throws -> Type?? where Type: Decodable, Type: Encodable {
        nil
    }
}
