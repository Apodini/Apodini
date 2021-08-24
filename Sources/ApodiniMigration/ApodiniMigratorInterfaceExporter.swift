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
@_implementationOnly import ApodiniVaporSupport
@_implementationOnly import Vapor

final class ApodiniMigratorInterfaceExporter: InterfaceExporter {
    static var parameterNamespace: [ParameterNamespace] = .individual
    
    private let app: Apodini.Application
    private var document = Document()
    private let logger: Logger
    private let documentConfig: DocumentConfiguration
    private let migrationGuideConfig: MigrationGuideConfiguration
    private var serverPath = ""
    
    init<W: WebService>(_ app: Apodini.Application, configuration: MigratorConfiguration<W>) {
        self.app = app
        self.documentConfig = configuration.documentConfig
        self.migrationGuideConfig = configuration.migrationGuideConfig
        self.logger = configuration.logger
        setServerPath()
    }
    
    public func export<H>(_ endpoint: Apodini.Endpoint<H>) where H: Handler {
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
    
    public func export<H>(blob endpoint: Apodini.Endpoint<H>) where H: Handler, H.Response.Content == Blob {
        export(endpoint)
    }
    
    public func finishedExporting(_ webService: WebServiceModel) {
        document.setVersion(.init(with: webService.context.get(valueFor: APIVersionContextKey.self)))
        handleDocument()
        handleMigrationGuide()
    }
    
    private func setServerPath() {
        let isHttps = app.http.tlsConfiguration != nil
        var hostName: String?
        var port: Int?
        if case let .hostname(configuredHost, port: configuredPort) = app.http.address {
            hostName = configuredHost
            port = configuredPort
        } else {
            let configuration = app.vapor.app.http.server.configuration
            hostName = configuration.hostname
            port = configuration.port
        }
        
        if let hostName = hostName, let port = port {
            let serverPath = "http\(isHttps ? "s" : "")://\(hostName):\(port)"
            self.serverPath = serverPath
            document.setServerPath(serverPath)
        }
    }
    
    private func handleDocument() {
        let format = documentConfig.format
        switch documentConfig.exportPath {
        case let .directory(path):
            do {
                let filePath = try document.write(at: path, outputFormat: format, fileName: document.fileName)
                logger.info("Document exported at \(filePath)")
            } catch {
                logger.error("Document export failed with error: \(error)")
            }
            
        case let .endpoint(path):
            let content = format.string(of: document)
            serve(content: content, at: path)
            logger.info("Document served at \(serverPath)\(path.withLeadingSlash) in \(format.rawValue) format")
        }
    }
    
    private func handleMigrationGuide() {
        do {
            switch migrationGuideConfig {
            case .none: return
            case let .compare(location, exportPath, format):
                let oldDocument: Document = try location.instance()
                let migrationGuide = MigrationGuide(for: oldDocument, rhs: document)
                try handleMigrationGuide(migrationGuide, for: exportPath, format: format)
            case let .read(location, exportPath, format):
                let migrationGuide: MigrationGuide = try location.instance()
                try handleMigrationGuide(migrationGuide, for: exportPath, format: format)
            }
        } catch {
            logger.error("Migration guide handling failed with error: \(error)")
        }
    }
    
    private func handleMigrationGuide(_ migrationGuide: MigrationGuide, for exportPath: ExportPath, format: FileFormat) throws {
        switch exportPath {
        case let .directory(path):
            let filePath = try migrationGuide.write(at: path, outputFormat: format, fileName: "migration_guide")
            logger.info("Migration guide exported at \(filePath)")
        case let .endpoint(path):
            let content = format.string(of: migrationGuide)
            serve(content: content, at: path)
            logger.info("Migration guide served at \(serverPath)\(path.withLeadingSlash) in \(format.rawValue) format")
        }
    }
    
    private func serve(content: String, at path: String) {
        app.vapor.app.get(path.withLeadingSlash.pathComponents) { _ -> String in
            content
        }
    }
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

// MARK: - String
fileprivate extension String {
    var withLeadingSlash: String {
        hasPrefix("/") ? self : "/\(self)"
    }
}
