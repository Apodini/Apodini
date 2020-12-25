//
//  Request.swift
//  
//
//  Created by Paul Schmiedmayer on 7/12/20.
//
import Foundation
import NIO
import protocol FluentKit.Database
import struct FluentKit.DatabaseID

protocol ApodiniRequest: CustomStringConvertible, CustomDebugStringConvertible {
    /// Returns a description of the Apodini Request.
    /// If the `ExporterRequest` also conforms to `CustomStringConvertible`, its `description`
    /// will be appended.
    var description: String { get }
    /// Returns a debug description of the Apodini Request.
    /// If the `ExporterRequest` also conforms to `CustomDebugStringConvertible`, its `debugDescription`
    /// will be appended.
    var debugDescription: String { get }

    var endpoint: AnyEndpoint { get }

    var eventLoop: EventLoop { get }

    var defaultDatabase: Database? { get }
    func database(_ id: DatabaseID?) -> Database?

    func retrieveParameter<Type: Codable>(_ type: Type.Type, id: UUID) throws -> Type
    func retrieveOptionalParameter<Type: Codable>(_ type: Type.Type, id: UUID) throws -> Type?

    func enterRequestContext<E, R>(with element: E, executing method: (E) -> EventLoopFuture<R>) -> EventLoopFuture<R>
    func enterRequestContext<E, R>(with element: E, executing method: (E) -> R) -> R
}

struct Request<I: InterfaceExporter, C: Component>: ApodiniRequest {
    var description: String {
        var description = "Apodini Request:\n"
        if let convertible = exporterRequest as? CustomStringConvertible {
            description += convertible.description
        }
        return description
    }
    var debugDescription: String {
        var debugDescription = "Apodini Request:\n"
        if let convertible = exporterRequest as? CustomDebugStringConvertible {
            debugDescription += convertible.debugDescription
        }
        return debugDescription
    }

    var exporter: I
    var exporterRequest: I.ExporterRequest

    var storedEndpoint: Endpoint<C>
    var endpoint: AnyEndpoint {
        storedEndpoint
    }

    var eventLoop: EventLoop

    var defaultDatabase: Database? {
        database(nil)
    }
    /// Use to inject a database in our test cases
    var databaseRetrieval: ((DatabaseID?) -> Database)?

    init(for exporter: I, with request: I.ExporterRequest, on endpoint: Endpoint<C>, running eventLoop: EventLoop) {
        self.exporter = exporter
        self.exporterRequest = request
        self.storedEndpoint = endpoint
        self.eventLoop = eventLoop
    }

    func database(_ id: DatabaseID?) -> Database? {
        if let retrieval = databaseRetrieval {
            return retrieval(id)
        }

        #warning("Fluent Databases aren't supported right now. Database setup and retrieval are unsolved problems right now!")
        fatalError("Databases aren't supporter right now")
    }

    func retrieveParameter<Type: Codable>(_ type: Type.Type = Type.self, id: UUID) throws -> Type {
        let optionalResult: Type? = try retrieveOptionalParameter(id: id)

        guard let result = optionalResult else {
            #warning("Create some Apodini defined error, which is returned to the exporter so it can encode a response.")
            fatalError("Didn't retrieve any parameters for a required parameter.")
        }

        return result
    }

    func retrieveOptionalParameter<Type: Codable>(_ type: Type.Type = Type.self, id: UUID) throws -> Type? {
        guard let endpointParameter = endpoint.findParameter(for: id) else {
            fatalError("Could not find the associated Parameter model for \(id) with type \(type). Something has gone horribly wrong!")
        }

        let visitor = ParameterRetrievalDelegation<Type, I>(exporter: exporter, request: exporterRequest)
        return try endpointParameter.accept(visitor)
    }
}

private struct ParameterRetrievalDelegation<Type: Codable, I: InterfaceExporter>: EndpointParameterThrowingVisitor {
    var exporter: I
    var request: I.ExporterRequest

    func visit<Value: Codable>(parameter: EndpointParameter<Value>) throws -> Type? {
        let value: Value? = try exporter.retrieveParameter(parameter, for: request)
        // swiftlint:disable:next force_cast
        return value as! Type?
    }
}

@propertyWrapper
// swiftlint:disable:next type_name
struct _Request: RequestInjectable {
    private var request: ApodiniRequest?
    
    
    var wrappedValue: ApodiniRequest {
        guard let request = request else {
            fatalError("You can only access the request while you handle a request")
        }
        
        return request
    }
    
    
    init() { }


    mutating func inject(using request: ApodiniRequest) throws {
        self.request = request
    }
}


struct AnyEncodable: Encodable {
    let value: Encodable

    func encode(to encoder: Encoder) throws {
        try self.value.encode(to: encoder)
    }
}
