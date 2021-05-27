//
//  RESTDependentConfiguration.swift
//  
//
//  Created by Philipp Zagar on 27.05.21.
//

public protocol RESTDependentStaticConfiguration: StaticConfiguration {}

public struct EmptyRESTDependentStaticConfiguration: RESTDependentStaticConfiguration {
    public func configure(_ app: Application, _ semanticModel: SemanticModelBuilder, parentConfiguration: ExporterConfiguration) { }
    
    public init() { }
}

extension Array where Element == RESTDependentStaticConfiguration {
    public func configure(_ app: Application, _ semanticModel: SemanticModelBuilder, parentConfiguration: ExporterConfiguration) {
        forEach {
            $0.configure(app, semanticModel, parentConfiguration: parentConfiguration)
        }
    }
}
