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
    typealias RESTAuditor = RESTAuditorConfiguration<Self>
    typealias HTTPAuditor = HTTPAuditorConfiguration<Self>
}

// TODO write test that _commands works
private var registeredCommand = false
private func getAuditCommand(_ auditCommand: ParsableCommand.Type) -> ParsableCommand.Type? {
    if !registeredCommand {
        registeredCommand = true
        return auditCommand
    }
    return nil
}

private var registeredInterfaceExporter = false
private func registerInterfaceExporter(_ app: Application) {
    if registeredInterfaceExporter {
        return
    }
    registeredInterfaceExporter = true
    
    let exporter = AuditInterfaceExporter(app)

    app.registerExporter(exporter: exporter)
}

public final class RESTAuditorConfiguration<Service: WebService>: DependentStaticConfiguration {
    public typealias ParentConfiguration = REST
    
    public var command: ParsableCommand.Type? {
        getAuditCommand(AuditCommand<Service>.self)
    }
    
    public func configure(_ app: Apodini.Application, parentConfiguration: REST.ExporterConfiguration) {
        //getSynsets()
        registerInterfaceExporter(app)
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
