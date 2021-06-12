//
//  DeltaInterfaceExporter.swift
//
//
//  Created by Eldi Cano on 14.05.21.
//

import Foundation
import Apodini
import ApodiniMigrator
import Logging
@_implementationOnly import ApodiniVaporSupport

public final class DeltaInterfaceExporter: StaticInterfaceExporter {
    public static var parameterNamespace: [ParameterNamespace] = .individual
    
    let app: Application
    var document: Document
    let logger: Logger
    var deltaConfiguration: DeltaConfiguration?
    
    public init(_ app: Application) {
        self.app = app
        document = Document()
        logger = Logger(label: "org.apodini.\(Self.self)")
        
        if let storage = app.storage.get(DeltaStorageKey.self) {
            deltaConfiguration = storage.configuration
        } else {
            logger.warning(
                """
                \(DeltaConfiguration.self) not set. Use \(DeltaConfiguration.self)() and `.absolutePath(_:)` to specify where `DeltaDocument` should
                be persisted locally.
                """
            )
        }
        
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
            logger.error(
                """
                Error encountered while building the `TypeInformation` of response with type \(responseType) for handler \(handlerName): \(error).
                Response type set to \(Null.self).
                """
            )
            response = .scalar(.null)
        }
        
        let errors: [ErrorCode] = [
            .init(code: 401, message: "Unauthorized"),
            .init(code: 403, message: "Forbidden"),
            .init(code: 404, message: "Not found"),
            .init(code: 500, message: "Internal server error")
        ]
        
        let migratorEndpoint = ApodiniMigrator.Endpoint(
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
    
    public func finishedExporting(_ webService: WebServiceModel) {
        if let documentPath = deltaConfiguration?.absolutePath {
            do {
                try document.export(at: documentPath + "/" + "delta_document.json")
            } catch {
                logger.error("Error encountered while exporting `DeltaDocument` at \(documentPath): \(error)")
            }
        } else {
            logger.warning(
                """
                \(DeltaConfiguration.self) not set. Use \(DeltaConfiguration.self)() and `.absolutePath(_:)` to specify where `DeltaDocument` should
                be persisted locally.
                """
            )
        }
    }
    
    private func setVersion<H: Handler>(from endpoint: Apodini.Endpoint<H>) {
        if let version = endpoint[Context.self].get(valueFor: APIVersionContextKey.self) {
            let migratorVersion: ApodiniMigrator.Version = .init(version)
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
}
