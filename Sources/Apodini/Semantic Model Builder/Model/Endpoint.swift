//
// Created by Andreas Bauer on 22.11.20.
//
import Foundation

/// A ``ParameterCollection`` provides access to an endpoint's ``EndpointParameter``s.
public protocol ParameterCollection {
    /// Provides access to the ``EndpointParameter``s related to this collection.
    var parameters: [AnyEndpointParameter] { get }
}

public extension ParameterCollection {
    /// This method returns the instance of a `AnyEndpointParameter` if the given `Endpoint` holds a parameter
    /// for the supplied parameter id. Otherwise nil is returned.
    ///
    /// - Parameter id: The parameter `id` to search for.
    /// - Returns: Returns the `AnyEndpointParameter` if a parameter with the given `id` exists on that `Endpoint`. Otherwise nil.
    func findParameter(for id: UUID) -> AnyEndpointParameter? {
        parameters.first { parameter in
            parameter.id == id
        }
    }
}

/// Models a single Endpoint which is identified by its PathComponents and its operation
public protocol AnyEndpoint: Blackboard, CustomStringConvertible, ParameterCollection {
    /// This method can be called, to export all `EndpointParameter`s of the given `Endpoint` on the supplied `BaseInterfaceExporter`.
    /// It will call the `BaseInterfaceExporter.exporterParameter(...)` method for every parameter on this `Endpoint`.
    ///
    /// This method is particularly useful to access the fully typed version of the `EndpointParameter`.
    ///
    /// - Parameter exporter: The `BaseInterfaceExporter` to export the parameters on.
    /// - Returns: The result of the individual `BaseInterfaceExporter.exporterParameter(...)` calls.
    @discardableResult
    func exportParameters<I: BaseInterfaceExporter>(on exporter: I) -> [I.ParameterExportOutput]
    
    func createAnyConnectionContext<I: InterfaceExporter>(for exporter: I) -> AnyConnectionContext<I>
}

protocol _AnyEndpoint: AnyEndpoint {
    /// Internal method which is called to call the `InterfaceExporter.export(...)` method on the given `exporter`.
    ///
    /// - Parameter exporter: The `BaseInterfaceExporter` used to export the given `Endpoint`
    /// - Returns: Whatever the export method of the `InterfaceExporter` returns (which equals to type `EndpointExporterOutput`) is returned here.
    @discardableResult
    func exportEndpoint<I: BaseInterfaceExporter>(on exporter: I) -> I.EndpointExportOutput
}


/// Models a single Endpoint which is identified by its PathComponents and its operation
public struct Endpoint<H: Handler>: _AnyEndpoint {
    private let blackboard: Blackboard

    public let handler: H
    
    init(
        handler: H,
        blackboard: Blackboard
    ) {
        self.handler = handler
        self.blackboard = blackboard
    }
    
    public subscript<S>(_ type: S.Type) -> S where S: KnowledgeSource {
        get {
            self.blackboard[type]
        }
        nonmutating set {
            self.blackboard[type] = newValue
        }
    }
    
    public func request<S>(_ type: S.Type) throws -> S where S: KnowledgeSource {
        try self.blackboard.request(type)
    }
    
    func exportEndpoint<I: BaseInterfaceExporter>(on exporter: I) -> I.EndpointExportOutput {
        exporter.export(self)
    }

    public func createConnectionContext<I: InterfaceExporter>(for exporter: I) -> ConnectionContext<I, H> {
        ConnectionContext(for: exporter, on: self)
    }
    
    public func createAnyConnectionContext<I: InterfaceExporter>(for exporter: I) -> AnyConnectionContext<I> {
        self.createConnectionContext(for: exporter).typeErased
    }

    /// Provides the ``EndpointParameters`` that correspond to the ``Parameter``s defined on the ``Handler`` of this ``Endpoint``
    public var parameters: [AnyEndpointParameter] {
        self[EndpointParameters.self]
    }

    @discardableResult
    public func exportParameters<I: BaseInterfaceExporter>(on exporter: I) -> [I.ParameterExportOutput] {
        self[EndpointParameters.self].exportParameters(on: exporter)
    }
}

extension Endpoint: CustomDebugStringConvertible {
    public var debugDescription: String {
        String(describing: self.handler)
    }
}

extension Endpoint: CustomStringConvertible {
    public var description: String {
        self[HandlerDescription.self]
    }
}
