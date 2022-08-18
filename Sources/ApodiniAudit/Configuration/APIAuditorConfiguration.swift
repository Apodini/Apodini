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

public final class APIAuditorConfiguration<Service: WebService>: DependentStaticConfiguration {
    public typealias InteralParentConfiguration = HTTPExporterConfiguration
    
    public var command: ParsableCommand.Type? {
        SharedAPIAuditorConfiguration.getAuditCommand(AuditCommand<Service>.self)
    }
    
    private let bestPractices: [BestPractice]
    
    public func configure(_ app: Apodini.Application, parentConfiguration: HTTPExporterConfiguration) {
        // This Configuration is only relevant if the webservice has been run through the audit CLI
        guard app.storage[AuditStorageKey.self] != nil else {
            return
        }
        
        // Register exporter with configured Best Practices
        let auditInterfaceExporter = AuditInterfaceExporter(app, parentConfiguration, bestPractices, String(describing: Service.self))
        app.registerExporter(exporter: auditInterfaceExporter)
    }
    
    public init(@AuditConfigurationBuilder bestPractices: () -> [BestPractice]) {
        self.bestPractices = bestPractices()
    }
    
    public convenience init() {
        self.init { }
    }
}

private enum SharedAPIAuditorConfiguration {
    // FUTURE write test that _commands works
    fileprivate static var registeredCommand = false
    fileprivate static func getAuditCommand(_ auditCommand: ParsableCommand.Type) -> ParsableCommand.Type? {
        if !registeredCommand {
            registeredCommand = true
            return auditCommand
        }
        return nil
    }
}

struct BestPracticesStorageKey: StorageKey {
    typealias Value = [BestPractice]
}

/// A configuration for a ``BestPractice``.
public protocol BestPracticeConfiguration {
    /// Produce a ``BestPractice`` instance with this configuration.
    func configure() -> BestPractice
}

public struct EmptyBestPracticeConfiguration<BP: BestPractice>: BestPracticeConfiguration {
    public func configure() -> BestPractice {
        BP()
    }
}
