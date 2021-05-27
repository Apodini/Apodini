//
//  StaticConfiguration.swift
//  
//
//  Created by Philipp Zagar on 21.05.21.
//

public protocol StaticConfiguration {
    func configure(_ app: Application, _ semanticModel: SemanticModelBuilder, parentConfiguration: ExporterConfiguration)
}

public struct EmptyStaticConfiguration: StaticConfiguration {
    public func configure(_ app: Application, _ semanticModel: SemanticModelBuilder, parentConfiguration: ExporterConfiguration) { }
    
    public init() { }
}

extension Array where Element == StaticConfiguration {
    public func configure(_ app: Application, _ semanticModel: SemanticModelBuilder, parentConfiguration: ExporterConfiguration) {
        forEach {
            $0.configure(app, semanticModel, parentConfiguration: parentConfiguration)
        }
    }
}
