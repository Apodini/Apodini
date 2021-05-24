//
//  StaticConfiguration.swift
//  
//
//  Created by Philipp Zagar on 21.05.21.
//

public protocol StaticConfiguration {
    func configure(_ app: Application, parentConfiguration: TopLevelExporterConfiguration)
}

public struct EmptyStaticConfiguration: StaticConfiguration {
    public func configure(_ app: Application, parentConfiguration: TopLevelExporterConfiguration) { }
    
    public init() { }
}

extension Array where Element == StaticConfiguration {
    public func configure(_ app: Application, parentConfiguration: TopLevelExporterConfiguration) {
        forEach {
            $0.configure(app, parentConfiguration: parentConfiguration)
        }
    }
}
