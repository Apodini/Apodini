//
//  File.swift
//  
//
//  Created by Eldi Cano on 07.08.21.
//

import Foundation
import Apodini
import ApodiniMigratorCore
import ApodiniMigratorCompare
import ApodiniMigratorShared
import Logging

@_implementationOnly import ApodiniVaporSupport
@_implementationOnly import Vapor

final class ApodiniMigratorInterfaceExporter: InterfaceExporter {
    static var parameterNamespace: [ParameterNamespace] = .individual
    
    private let app: Apodini.Application
    private var document = Document()
    private let logger = Logger(label: "org.apodini.migrator")
    private var configuration: MigratorConfiguration
    
    init(_ app: Apodini.Application, configuration: MigratorConfiguration) {
        self.app = app
        self.configuration = configuration
        
        setServerPath()
    }
    
    public func export<H>(_ endpoint: Apodini.Endpoint<H>) where H: Handler {
        let handlerName = endpoint[HandlerDescription.self]
        let operation = endpoint[Apodini.Operation.self]
        let identifier = endpoint[AnyHandlerIdentifier.self]
        let params = endpoint.parameters.migratorParameters(of: H.self, with: logger)
        
        let path = endpoint.absolutePath.asPathString()
        let responseType = endpoint[ResponseType.self].type
        let response: TypeInformation
        do {
            response = try TypeInformation(type: responseType)
        } catch {
            if responseType == Blob.self {
                response = .scalar(.data)
            } else {
                logger.error(
                    """
                    Error encountered while building the `TypeInformation` of response with type \(responseType) for handler \(handlerName): \(error).
                    Response type set to \(Null.self).
                    """
                )
                response = .scalar(.null)
            }
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
            absolutePath: path,
            parameters: params,
            response: response,
            errors: errors
        )
        
        document.add(endpoint: migratorEndpoint)
        
        setVersion(from: endpoint)
    }
    
    public func export<H>(blob endpoint: Apodini.Endpoint<H>) where H: Handler, H.Response.Content == Blob {
        export(endpoint)
    }
    
    public func finishedExporting(_ webService: WebServiceModel) {
        handleDocument()
        handleMigrationGuide()
    }
    
    private func setVersion<H: Handler>(from endpoint: Apodini.Endpoint<H>) {
        if let version = endpoint[Context.self].get(valueFor: APIVersionContextKey.self) {
            let migratorVersion: ApodiniMigratorCore.Version = .init(version)
            if document.metaData.version != migratorVersion {
                document.setVersion(migratorVersion)
            }
        }
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
            document.setServerPath(serverPath)
        }
    }
    
    private func handleDocument() {
        let config = configuration.documentConfig
        let outputFormat = config.outputFormat
        switch config.exportPath {
        case let .directory(path):
            do {
                let filePath = try document.write(at: path, outputFormat: outputFormat, fileName: document.fileName)
                logger.info("Document exported at \(filePath)")
            } catch {
                logger.error("Document export failed with error: \(error)")
            }
            
        case let .endpoint(path):
            let content = outputFormat == .json ? document.json : document.yaml
            serve(content: content, at: path)
            logger.info("Document served at \(path) in \(outputFormat.rawValue) format")
        }
    }

    private func handleMigrationGuide() {
        let config = configuration.migrationGuideConfig
        do {
            switch config {
            case .none: return
            case let .compare(documentPath, exportPath, format):
                let oldDocument = try Document.decode(from: Path(documentPath))
                let migrationGuide = MigrationGuide(for: oldDocument, rhs: document)
                try handleMigrationGuide(migrationGuide, for: exportPath, outputFormat: format)
            case let .read(fromPath, exportPath, format):
                let migrationGuide = try MigrationGuide.decode(from: Path(fromPath))
                try handleMigrationGuide(migrationGuide, for: exportPath, outputFormat: format)
            }
        } catch {
            logger.error("Migration guide handling failed with error: \(error)")
        }
    }
    
    private func handleMigrationGuide(_ migrationGuide: MigrationGuide, for exportPath: ExportPath, outputFormat: OutputFormat) throws {
        switch exportPath {
        case let .directory(path):
            let filePath = try migrationGuide.write(at: path, outputFormat: outputFormat, fileName: "migration_guide")
            logger.info("Migration guide exported at \(filePath)")
        case let .endpoint(path):
            let content = outputFormat == .json ? migrationGuide.json : migrationGuide.yaml
            serve(content: content, at: path)
            logger.info("Migration guide served at \(path) in \(outputFormat.rawValue) format")
        }
    }
    
    private func serve(content: String, at path: String) {
        app.vapor.app.get(path.withLeadingSlash.pathComponents) { _ -> String in
            content
        }
    }
}

// MARK: - String
fileprivate extension String {
    var withLeadingSlash: String {
        hasPrefix("/") ? self : "/\(self)"
    }
}
