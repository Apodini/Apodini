//
//  StaticConfiguration.swift
//  
//
//  Created by Philipp Zagar on 21.05.21.
//

public protocol StaticConfiguration {
    func configure(_ app: Application, _ semanticModel: SemanticModelBuilder, parentConfiguration: ExporterConfiguration)
}
