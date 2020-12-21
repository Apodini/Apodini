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

class GRPCSemanticModelBuilder: SemanticModelBuilder {
    var services: [String: GRPCService]

    override init(_ app: Application) {
        self.services = [:]
        super.init(app)
    }

    override func register<C: Component>(component: C, withContext context: Context) {
        super.register(component: component, withContext: context)

        var serviceName = context.get(valueFor: GRPCServiceNameContextKey.self)
        // if no explicit servicename is provided via the modifier,
        // simply use the PathComponents to come up with one
        if serviceName == GRPCServiceNameContextKey.defaultValue {
            let components = context.get(valueFor: PathComponentContextKey.self)
            let builder = StringPathBuilder(components, delimiter: "")
            serviceName = builder.build()
        }

        var methodName = context.get(valueFor: GRPCMethodNameContextKey.self)
        // if no explicit methodname is provided via the modifier,
        // we have to rely on the component name
        if methodName == GRPCMethodNameContextKey.defaultValue {
            methodName = "\(C.self)".lowercased()
        }

        // expose the new component via a GRPCService
        // currently unary enpoints are considered here
        if let service = services[serviceName] {
            service.exposeUnaryEndpoint(name: methodName, for: component, with: context)
        } else {
            let service = GRPCService(name: serviceName, using: app)
            service.exposeUnaryEndpoint(name: methodName, for: component, with: context)
            services[serviceName] = service
            app.logger.info("Exposed new gRPC service with name: \(serviceName)")
        }
        app.logger.info("Exposed new gRPC endpoint for service \(serviceName) with name: \(methodName)")
    }
}
