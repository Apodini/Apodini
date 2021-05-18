//
//  DeltaInterfaceExporter.swift
//
//
//  Created by Eldi Cano on 14.05.21.
//

import Foundation
import Apodini
import ApodiniMigrator
@_implementationOnly import ApodiniVaporSupport

public final class DeltaInterfaceExporter: StaticInterfaceExporter {
    public static var parameterNamespace: [ParameterNamespace] = .individual
    
    let app: Application
    var document: Document
    
    public init(_ app: Application) {
        self.app = app
        document = Document()
        
        setServerPath()
    }
    
    public func export<H>(_ endpoint: Apodini.Endpoint<H>) where H: Handler {
        let handlerName = endpoint[HandlerDescription.self]
        let operation = endpoint[Apodini.Operation.self]
        let identifier = endpoint[AnyHandlerIdentifier.self]
        let params = try! endpoint.parameters.migratorParameters(referencedIn: &document)
        
        let path = endpoint.absolutePath.asPathString()
        let response = document.reference(try! TypeInformation(type: endpoint[ResponseType.self].type))
        
        let errors: [ErrorCode] = [
            .init(code: 401, message: "Unauthorized"),
            .init(code: 403, message: "Forbidden"),
            .init(code: 404, message: "Not found"),
            .init(code: 500, message: "Internal server error")
        ]

        let endpoint = ApodiniMigrator.Endpoint(
            handlerName: handlerName,
            deltaIdentifier: identifier.rawValue,
            operation: .init(operation),
            absolutePath: path,
            parameters: params,
            response: response,
            errors: errors
        )
        document.add(endpoint: endpoint)
    }
    
    public func finishedExporting(_ webService: WebServiceModel) {
        try! document.export(at: Path("/Users/eld/Desktop/document.json"))
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

extension ApodiniMigrator.Parameter {
    static func parameter(
        from: Apodini.AnyEndpointParameter,
        referencedIn document: inout Document)
    throws -> ApodiniMigrator.Parameter {
        let hasDefaultValue = from.typeErasuredDefaultValue != nil
        var typeInformation = try TypeInformation(type: from.propertyType)
        if from.nilIsValidValue {
            typeInformation = typeInformation.asOptional
        }
        typeInformation = document.reference(typeInformation)
        return .init(
            parameterName: from.name,
            typeInformation: typeInformation,
            hasDefaultValue: hasDefaultValue,
            parameterType: .init(from.parameterType))
    }
}

extension Array where Element == Apodini.AnyEndpointParameter {
    func migratorParameters(referencedIn document: inout Document) throws -> [ApodiniMigrator.Parameter] {
        try map { try ApodiniMigrator.Parameter.parameter(from: $0, referencedIn: &document) }
    }
}

extension ApodiniMigrator.Operation {
    init(_ from: Apodini.Operation) {
        switch from {
        case .create: self = .create
        case .read: self = .read
        case .update: self = .update
        case .delete: self = .delete
        }
    }
}

extension ApodiniMigrator.ParameterType {
    init(_ from: Apodini.ParameterType) {
        switch from {
        case .lightweight: self = .lightweight
        case .content:  self = .content
        case .path: self = .path
        case .header: self = .header
        }
    }
}

extension ApodiniMigrator.Version {
    init(_ from: Apodini.Version) {
        self.init(
            prefix: from.prefix,
            major: from.major,
            minor: from.minor,
            patch: from.patch
        )
    }
}
