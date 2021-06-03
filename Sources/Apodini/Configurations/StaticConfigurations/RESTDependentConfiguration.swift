//
//  RESTDependentConfiguration.swift
//  
//
//  Created by Philipp Zagar on 27.05.21.
//

/// `RESTDependentStaticConfiguration`s are used to register static services dependend on the `RESTInterfaceExporter`
public protocol RESTDependentStaticConfiguration: StaticConfiguration {}

/// The default configuration is an `EmptyRESTDependentStaticConfiguration`
public struct EmptyRESTDependentStaticConfiguration: RESTDependentStaticConfiguration {
    public func configure(_ app: Application, _ semanticModel: SemanticModelBuilder, parentConfiguration: ExporterConfiguration) { }
    
    public init() { }
}

extension Array where Element == RESTDependentStaticConfiguration {
    /**
     A method that handels the configuration of dependend static exporters
     - Parameters:
     - app: The `Vapor.Application` which is used to register the configuration in Apodini
     - semanticModel: The `SemanticModelBuilder` where the services are registered
     - parentConfiguration: The `Configuration` of the parent of the dependend static exporters
     */
    public func configure(_ app: Application, _ semanticModel: SemanticModelBuilder, parentConfiguration: ExporterConfiguration) {
        forEach {
            $0.configure(app, semanticModel, parentConfiguration: parentConfiguration)
        }
    }
}
