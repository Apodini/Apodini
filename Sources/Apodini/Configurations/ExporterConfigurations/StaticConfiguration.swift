//
//  StaticConfiguration.swift
//  
//
//  Created by Philipp Zagar on 21.05.21.
//

public protocol StaticConfiguration {
    func configure(_ app: Application, _ semanticModel: SemanticModelBuilder, parentConfiguration: TopLevelExporterConfiguration)
}

public struct EmptyStaticConfiguration: StaticConfiguration {
    public func configure(_ app: Application, _ semanticModel: SemanticModelBuilder, parentConfiguration: TopLevelExporterConfiguration = TopLevelExporterConfiguration()) { }
    
    public init() { }
}

extension Array where Element == StaticConfiguration {
    public func configure(_ app: Application, _ semanticModel: SemanticModelBuilder, parentConfiguration: TopLevelExporterConfiguration = TopLevelExporterConfiguration()) {
        forEach {
            $0.configure(app, semanticModel, parentConfiguration: parentConfiguration)
        }
    }
}
