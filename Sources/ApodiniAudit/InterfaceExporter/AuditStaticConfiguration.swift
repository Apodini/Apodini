//
//  File.swift
//  
//
//  Created by Simon Bohnen on 4/8/22.
//

import Foundation
import Apodini
import ApodiniREST
import ApodiniHTTP
import ArgumentParser

// MARK: - WebService
public extension WebService {
    /// A typealias for ``APIAuditorConfiguration``
    typealias APIAuditor = APIAuditorConfiguration<Self>
}

private var firstRun = true

public final class APIAuditorConfiguration<Service: WebService>: RESTDependentStaticConfiguration, HTTPDependentStaticConfiguration {
    public var command: ParsableCommand.Type {
        if firstRun {
            firstRun = false
            return AuditCommand<Service>.self
        }
        return EmptyCommand.self
    }
    
    public func configure(_ app: Apodini.Application, parentConfiguration: REST.ExporterConfiguration) {
        
    }
    
    public func configure(_ app: Apodini.Application, parentConfiguration: HTTP.ExporterConfiguration) {
        
    }
    
    public init() { }
}
