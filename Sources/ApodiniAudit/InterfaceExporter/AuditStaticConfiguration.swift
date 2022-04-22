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
    typealias APIAuditor = APIAuditorConfiguration<Self>
}

public final class APIAuditorConfiguration<Service: WebService>: DependentStaticConfiguration {
    public typealias InteralParentConfiguration = HTTPExporterConfiguration
    
    public var command: ParsableCommand.Type? {
        SharedAPIAuditorConfiguration.getAuditCommand(AuditCommand<Service>.self)
    }
    
    public func configure(_ app: Apodini.Application, parentConfiguration: HTTPExporterConfiguration) {
        SharedAPIAuditorConfiguration.registerInterfaceExporter(app, parentConfiguration)
    }
    
    public init() { }
}

private final class SharedAPIAuditorConfiguration {
    // FUTURE write test that _commands works
    fileprivate static var registeredCommand = false
    fileprivate static func getAuditCommand(_ auditCommand: ParsableCommand.Type) -> ParsableCommand.Type? {
        if !registeredCommand {
            registeredCommand = true
            return auditCommand
        }
        return nil
    }

    fileprivate static var registeredInterfaceExporter = false
    fileprivate static func registerInterfaceExporter(_ app: Application, _ parentConfiguration: HTTPExporterConfiguration) {
        if registeredInterfaceExporter {
            return
        }
        registeredInterfaceExporter = true
        
        let exporter = AuditInterfaceExporter(app, parentConfiguration)

        app.registerExporter(exporter: exporter)
    }
}
