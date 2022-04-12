//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini
import ApodiniREST
import ApodiniHTTP
import ArgumentParser

// MARK: - WebService
public extension WebService {
    /// A typealias for ``APIAuditorConfiguration``
    typealias RESTAuditor = RESTAuditorConfiguration<Self>
    typealias HTTPAuditor = HTTPAuditorConfiguration<Self>
}

// TODO test that _commands works
private var firstRun = true
private func getAuditCommand(_ auditCommand: ParsableCommand.Type) -> ParsableCommand.Type? {
    if firstRun {
        firstRun = false
        return auditCommand
    }
    return nil
}

public final class RESTAuditorConfiguration<Service: WebService>: DependentStaticConfiguration {
    public typealias ParentConfiguration = REST
    
    public var command: ParsableCommand.Type? {
        getAuditCommand(AuditCommand<Service>.self)
    }
    
    public func configure(_ app: Apodini.Application, parentConfiguration: REST.ExporterConfiguration) {
        //getSynsets()
    }
    
    public init() { }
}

public final class HTTPAuditorConfiguration<Service: WebService>: DependentStaticConfiguration {
    public typealias ParentConfiguration = HTTP
    
    public var command: ParsableCommand.Type? {
        getAuditCommand(AuditCommand<Service>.self)
    }
    
    public func configure(_ app: Apodini.Application, parentConfiguration: HTTP.ExporterConfiguration) {
        
    }
    
    public init() { }
}
