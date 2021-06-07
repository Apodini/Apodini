//
//  GRPCDependentConfiguration.swift
//  
//
//  Created by Philipp Zagar on 27.05.21.
//

/// `GRPCDependentStaticConfiguration`s are used to register static services dependend on the `GRPCInterfaceExporter`
public protocol GRPCDependentStaticConfiguration: StaticConfiguration {}

/// The default configuration is an `EmptyGRPCDependentStaticConfiguration`
public struct EmptyGRPCDependentStaticConfiguration: GRPCDependentStaticConfiguration {
    public func configure(_ app: Application, parentConfiguration: ExporterConfiguration) { }
    
    public init() { }
}

extension Array where Element == GRPCDependentStaticConfiguration {
    /**
     A method that handels the configuration of dependend static exporters
     - Parameters:
         - app: The `Vapor.Application` which is used to register the configuration in Apodini
         - parentConfiguration: The `Configuration` of the parent of the dependend static exporters
     */
    public func configure(_ app: Application, parentConfiguration: ExporterConfiguration) {
        forEach {
            $0.configure(app, parentConfiguration: parentConfiguration)
        }
    }
}
