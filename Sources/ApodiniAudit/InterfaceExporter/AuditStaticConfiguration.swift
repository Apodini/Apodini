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
    typealias RESTAuditor = RESTAuditorConfiguration
    typealias HTTPAuditor = HTTPAuditorConfiguration
}

private var auditCommand: ParsableCommand.Type? = EmptyCommand.self // TODO AuditCommand.self
private func getAuditCommand() -> ParsableCommand.Type? {
    guard let command = auditCommand else {
        return nil
    }
    auditCommand = nil
    return command
}

public final class RESTAuditorConfiguration: DependentStaticConfiguration {
    public typealias ParentConfiguration = REST
    
    public var command: ParsableCommand.Type? {
        getAuditCommand()
    }
    
    public func configure(_ app: Apodini.Application, parentConfiguration: REST.ExporterConfiguration) {
        //getSynsets()
    }
    
    public init() { }
}

public final class HTTPAuditorConfiguration: DependentStaticConfiguration {
    public typealias ParentConfiguration = HTTP
    
    public var command: ParsableCommand.Type? {
        getAuditCommand()
    }
    
    public func configure(_ app: Apodini.Application, parentConfiguration: HTTP.ExporterConfiguration) {
        
    }
    
    public init() { }
}
