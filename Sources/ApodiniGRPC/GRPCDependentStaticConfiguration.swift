//
//  GRPCDependentStaticConfiguration.swift
//  
//
//  Created by Philipp Zagar on 27.05.21.
//

import Apodini

/// `GRPCDependentStaticConfiguration`s are used to register static services dependend on the `GRPCInterfaceExporter`
public protocol GRPCDependentStaticConfiguration {
    func configure(_ app: Application, parentConfiguration: GRPCExporterConfiguration)
}

/// The default configuration is an `EmptyGRPCDependentStaticConfiguration`
public struct EmptyGRPCDependentStaticConfiguration: GRPCDependentStaticConfiguration {
    public func configure(_ app: Application, parentConfiguration: GRPCExporterConfiguration) { }
    
    public init() { }
}

extension Array where Element == GRPCDependentStaticConfiguration {
    /**
     A method that handels the configuration of dependend static exporters
     - Parameters:
         - app: The `Vapor.Application` which is used to register the configuration in Apodini
         - parentConfiguration: The `Configuration` of the parent of the dependend static exporters
     */
    func configure(_ app: Application, parentConfiguration: GRPCExporterConfiguration) {
        forEach {
            $0.configure(app, parentConfiguration: parentConfiguration)
        }
    }
}
