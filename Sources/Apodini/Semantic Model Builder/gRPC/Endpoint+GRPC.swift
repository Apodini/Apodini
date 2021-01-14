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
        if let serviceName = self.context.get(valueFor: GRPCServiceNameContextKey.self) {
            return serviceName
        }

        // if no explicit servicename is provided via the modifier,
        // simply use the PathComponents to come up with one
        return self.absolutePath.asPathString(delimiter: "", parameterEncoding: .name)
            .capitalized
            .appending("Service")
    }

    /// The name of the method that is exported
    /// by the Protobuffer and GRPC exporters
    /// for the `handle` method of this `Endpoint`.
    var methodName: String {
        if let methodName = self.context.get(valueFor: GRPCMethodNameContextKey.self) {
            return methodName
        }
        // if no explicit methodname is provided via the modifier,
        // we have to rely on the component name
        return "\(H.self)".lowercased()
    }
}
