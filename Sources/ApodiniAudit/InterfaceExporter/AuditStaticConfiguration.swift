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
    typealias APIAuditor = APIAuditorConfiguration<Self>
}

private var firstRun = true

public final class APIAuditorConfiguration<Service: WebService>: RESTDependentStaticConfiguration, HTTPDependentStaticConfiguration {
    public var command: ParsableCommand.Type? {
        if firstRun {
            firstRun = false
            return AuditCommand<Service>.self
        }
        return EmptyCommand.self
    }
    
    public func configure(_ app: Apodini.Application, parentConfiguration: REST.ExporterConfiguration) {
        getSynsets()
    }
    
    public func configure(_ app: Apodini.Application, parentConfiguration: HTTP.ExporterConfiguration) {
        
    }
    
    public init() { }
}
