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
        getAuditCommand(AuditCommand<Service>.self)
    }
    
    // TODO add rest flag to HTTPExporterConfiguration
    public func configure(_ app: Apodini.Application, parentConfiguration: HTTPExporterConfiguration) {
        registerInterfaceExporter(app, mode: .rest)
    }
    
    public init() { }
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
private func registerInterfaceExporter(_ app: Application, mode: AuditMode) {
    if registeredInterfaceExporter {
        return
    }
    registeredInterfaceExporter = true
    
    let exporter = AuditInterfaceExporter(app, mode: mode)

    app.registerExporter(exporter: exporter)
}
