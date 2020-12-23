//
//  GRPCSemanticModelBuilder.swift
//
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

@_implementationOnly import Vapor
@_implementationOnly import GRPC
import NIOHPACK
import ProtobufferCoding

class GRPCSemanticModelBuilder: InterfaceExporter {
    let app: Application
    var services: [String: GRPCService]

    required init(_ app: Application) {
        self.app = app
        self.services = [:]
    }

    func export(_ endpoint: Endpoint) {
        var serviceName = endpoint.context.get(valueFor: GRPCServiceNameContextKey.self)
        // if no explicit servicename is provided via the modifier,
        // simply use the PathComponents to come up with one
        if serviceName == GRPCServiceNameContextKey.defaultValue {
            let components = endpoint.context.get(valueFor: PathComponentContextKey.self)
            let builder = StringPathBuilder(components, delimiter: "")
            serviceName = builder.build()
        }

        var methodName = endpoint.context.get(valueFor: GRPCMethodNameContextKey.self)
        // if no explicit methodname is provided via the modifier,
        // we have to rely on the component name
        if methodName == GRPCMethodNameContextKey.defaultValue {
            methodName = endpoint.componentName.lowercased()
        }

        let requestHandler = endpoint.requestHandler

        // expose the new component via a GRPCService
        // currently unary enpoints are considered here
        if let service = services[serviceName] {
            service.exposeUnaryEndpoint(name: methodName, requestHandler: requestHandler)
        } else {
            let service = GRPCService(name: serviceName, using: app)
            service.exposeUnaryEndpoint(name: methodName, requestHandler: requestHandler)
            services[serviceName] = service
            app.logger.info("Exposed new gRPC service with name: \(serviceName)")
        }
        app.logger.info("Exposed new gRPC endpoint for service \(serviceName) with name: \(methodName)")
    }
}
