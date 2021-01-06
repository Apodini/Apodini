//
//  Endpoint+GRPC.swift
//  
//
//  Created by Moritz Schüll on 04.01.21.
//

import Foundation

/// Provides utility functionality that is common to
/// both, the `ProtobufferInterfaceExporter` and
/// the `GRPCInterfaceExporter`.

extension Endpoint {
    /// The name of the service that is exported by
    /// the Protobuffer and GRPC exporters
    /// for this `Endpoint`.
    var serviceName: String {
        var serviceName = self.context.get(valueFor: GRPCServiceNameContextKey.self)
        // if no explicit servicename is provided via the modifier,
        // simply use the PathComponents to come up with one
        if serviceName == GRPCServiceNameContextKey.defaultValue {
            let pathComponents = self.context.get(valueFor: PathComponentContextKey.self)
            serviceName = pathComponents.asPathString(delimiter: "")
                .capitalized
                .appending("Service")
        }
        return serviceName
    }

    /// The name of the method that is exported
    /// by the Protobuffer and GRPC exporters
    /// for the `handle` method of this `Endpoint`.
    var methodName: String {
        var methodName = self.context.get(valueFor: GRPCMethodNameContextKey.self)
        // if no explicit methodname is provided via the modifier,
        // we have to rely on the component name
        if methodName == GRPCMethodNameContextKey.defaultValue {
            methodName = "\(H.self)".lowercased()
        }
        return methodName
    }
}
