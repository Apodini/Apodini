//
//  GRPCDependentConfiguration.swift
//  
//
//  Created by Philipp Zagar on 27.05.21.
//

public protocol GRPCDependentStaticConfiguration: StaticConfiguration {}

public struct EmptyGRPCDependentStaticConfiguration: GRPCDependentStaticConfiguration {
    public func configure(_ app: Application, _ semanticModel: SemanticModelBuilder, parentConfiguration: ExporterConfiguration) { }
    
    public init() { }
}

extension Array where Element == GRPCDependentStaticConfiguration {
    public func configure(_ app: Application, _ semanticModel: SemanticModelBuilder, parentConfiguration: ExporterConfiguration) {
        forEach {
            $0.configure(app, semanticModel, parentConfiguration: parentConfiguration)
        }
    }
}
