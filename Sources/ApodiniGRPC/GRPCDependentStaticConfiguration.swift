//
//  GRPCDependentStaticConfiguration.swift
//  
//
//  Created by Philipp Zagar on 27.05.21.
//

import Apodini

/// `GRPCDependentStaticConfiguration`s are used to register static services dependend on the `GRPCInterfaceExporter`
@available(macOS 12.0, *)
public protocol GRPCDependentStaticConfiguration {
    /// A method that handels the configuration of dependend static exporters
    /// - Parameters:
    ///    - app: The `Vapor.Application` which is used to register the configuration in Apodini
    ///    - parentConfiguration: The `GRPCExporterConfiguration` of the parent of the dependend exporter
    func configure(_ app: Application, parentConfiguration: GRPC.ExporterConfiguration)
}

/// The default configuration is an `EmptyGRPCDependentStaticConfiguration`
@available(macOS 12.0, *)
public struct EmptyGRPCDependentStaticConfiguration: GRPCDependentStaticConfiguration {
    public func configure(_ app: Application, parentConfiguration: GRPC.ExporterConfiguration) { }
    
    public init() { }
}

@available(macOS 12.0, *)
extension Array where Element == GRPCDependentStaticConfiguration {
    /// A method that handels the configuration of dependend static exporters
    /// - Parameters:
    ///    - app: The `Vapor.Application` which is used to register the configuration in Apodini
    ///    - parentConfiguration: The `GRPCExporterConfiguration` of the parent of the dependend static exporters
    func configure(_ app: Application, parentConfiguration: GRPC.ExporterConfiguration) {
        forEach {
            $0.configure(app, parentConfiguration: parentConfiguration)
        }
    }
}
