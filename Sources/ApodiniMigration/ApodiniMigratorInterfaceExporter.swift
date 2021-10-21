//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini
import ApodiniMigrator
@_implementationOnly import Logging
import ApodiniNetworking


/// Identifying storage key for `ApodiniMigrator` ``Document``
public struct MigratorDocumentStorageKey: Apodini.StorageKey {
    public typealias Value = Document
}

/// Identifying storage key for `ApodiniMigrator` ``MigrationGuide``
public struct MigrationGuideStorageKey: Apodini.StorageKey {
    public typealias Value = MigrationGuide
}

// MARK: - MigratorPathStringBuilder
private struct MigratorPathStringBuilder: PathBuilderWithResult {
    private static let separator = "/"
    private var components: [String] = []

    mutating func append(_ string: String) {
        components.append(string)
    }

    mutating func append<C: Codable>(_ parameter: EndpointPathParameter<C>) {
        components.append("{\(parameter.name)}")
    }

    func result() -> String {
        components.joined(separator: Self.separator)
    }
}

// MARK: - MigratorItem
protocol MigratorItem: Encodable {
    static var itemName: String { get }
    var fileName: String { get }
}

// MARK: - Document + MigratorItem
extension Document: MigratorItem {
    static var itemName: String {
        "API Document"
    }
}

// MARK: - MigrationGuide + MigratorItem
extension MigrationGuide: MigratorItem {
    static var itemName: String {
        "Migration Guide"
    }
    
    var fileName: String {
        "migration_guide"
    }
}

// MARK: - ApodiniMigratorInterfaceExporter
final class ApodiniMigratorInterfaceExporter: InterfaceExporter {
    static var parameterNamespace: [ParameterNamespace] = .global

    private let app: Apodini.Application
    private var document = Document()
    private let documentConfig: DocumentConfiguration?
    private let migrationGuideConfig: MigrationGuideConfiguration?
    private var serverPath = ""
    private let logger = Logger(label: "org.apodini.migrator")

    init<W: WebService>(_ app: Apodini.Application, configuration: MigratorConfiguration<W>) {
        self.app = app
        self.documentConfig = configuration.documentConfig ?? app.storage.get(DocumentConfigStorageKey.self)
        self.migrationGuideConfig = configuration.migrationGuideConfig ?? app.storage.get(MigrationGuideConfigStorageKey.self)
    }

    func export<H>(_ endpoint: Apodini.Endpoint<H>) where H: Handler {
        let handlerName = endpoint[HandlerDescription.self]
        let operation = endpoint[Apodini.Operation.self]
        let identifier = endpoint[AnyHandlerIdentifier.self]
        let params = endpoint.parameters.migratorParameters(of: H.self, with: logger)

        let endpointPath = endpoint[EndpointPathComponentsHTTP.self].value
        let absolutePath = endpointPath.build(with: MigratorPathStringBuilder.self)
        let responseType = endpoint[ResponseType.self].type
        let response: TypeInformation
        do {
            response = try TypeInformation(type: responseType)
        } catch {
            logger.error(
                """
                Error encountered while building the `TypeInformation` of response with type \(responseType) for handler \(handlerName): \(error).
                Using \(Data.self) for the response type.
                """
            )
            response = .scalar(.data)
        }

        let errors: [ErrorCode] = [
            .init(code: 401, message: "Unauthorized"),
            .init(code: 403, message: "Forbidden"),
            .init(code: 404, message: "Not found"),
            .init(code: 500, message: "Internal server error")
        ]

        let migratorEndpoint = ApodiniMigratorCore.Endpoint(
            handlerName: handlerName,
            deltaIdentifier: identifier.rawValue,
            operation: .init(operation),
            absolutePath: absolutePath,
            parameters: params,
            response: response,
            errors: errors
        )

        document.add(endpoint: migratorEndpoint)
    }

    func export<H>(blob endpoint: Apodini.Endpoint<H>) where H: Handler, H.Response.Content == Blob {
        export(endpoint)
    }

    func finishedExporting(_ webService: WebServiceModel) {
        setServerPath()
        document.setVersion(.init(with: webService.context.get(valueFor: APIVersionContextKey.self)))
        app.storage.set(MigratorDocumentStorageKey.self, to: document)
        
        handleDocument()
        handleMigrationGuide()
    }

    private func setServerPath() {
//        var hostName: String?
//        var port: Int?
//        if case let .hostname(configuredHost, port: configuredPort) = app.http.address {
//            hostName = configuredHost
//            port = configuredPort
//        } else {
//            let configuration = app.vapor.app.http.server.configuration
//            hostName = configuration.hostname
//            port = configuration.port
//        }
//
//        if let hostName = hostName, let port = port {
//            let serverPath = "http\(app.http.tlsConfiguration != nil ? "s" : "")://\(hostName):\(port)"
//            self.serverPath = serverPath
//            document.setServerPath(serverPath)
//        }
        self.serverPath = app.http.addressStringValue
        document.setServerPath(serverPath)
    }

    private func handleDocument() {
        guard let exportOptions = documentConfig?.exportOptions else {
            return logger.notice("No configuration provided to handle the document of the current version")
        }
        
        handle(document, with: exportOptions)
    }
    
    private func handleMigrationGuide() {
        guard let migrationGuideConfig = migrationGuideConfig else {
            return logger.notice("No migration guide configurations provided")
        }
        
        do {
            let exportOptions = migrationGuideConfig.exportOptions
            var migrationGuide: MigrationGuide?
            if let migrationGuidePath = migrationGuideConfig.migrationGuidePath {
                migrationGuide = try MigrationGuide.decode(from: migrationGuidePath.asPath)
            } else if let oldDocumentPath = migrationGuideConfig.oldDocumentPath {
                migrationGuide = MigrationGuide(for: try Document.decode(from: oldDocumentPath.asPath), rhs: document)
            }
            if let migrationGuide = migrationGuide {
                handle(migrationGuide, with: exportOptions)
                app.storage.set(MigrationGuideStorageKey.self, to: migrationGuide)
            }
        } catch {
            logger.error("Migration guide handling failed with error: \(error)")
        }
    }
    
    private func handle<I: MigratorItem, E: ExportOptions>(_ migratorItem: I, with exportOptions: E) {
        let format = exportOptions.format
        let itemName = I.itemName
        if var endpoint = exportOptions.endpoint {
            endpoint = endpoint.hasPrefix("/") ? endpoint : "/\(endpoint)"
            //app.vapor.app.get(endpoint.pathComponents) { _ -> String in
            //    format.string(of: migratorItem)
            //}
            app.httpServer.registerRoute(.GET, endpoint.httpPathComponents) { _ -> String in
                format.string(of: migratorItem)
            }
            logger.info("\(itemName) served at \(serverPath)\(endpoint) in \(format.rawValue) format")
        }
        
        if let directory = exportOptions.directory {
            do {
                let filePath = try migratorItem.write(at: directory, outputFormat: format, fileName: migratorItem.fileName)
                logger.info("\(itemName) exported at \(filePath) in \(format.rawValue) format")
            } catch {
                logger.error("\(itemName) export at \(directory) failed with error: \(error)")
            }
        }
        
        if exportOptions.directory == nil && exportOptions.endpoint == nil {
            logger.notice("No export paths provided to handle \(itemName)")
        }
    }
}
