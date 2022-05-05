//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
public protocol AnyEndpoint: SharedRepository, CustomStringConvertible, ParameterCollection {
    /// This method can be called, to export all `EndpointParameter`s of the given `Endpoint` on the supplied `InterfaceExporter`.
    /// It will call the `InterfaceExporter.exporterParameter(...)` method for every parameter on this `Endpoint`.
    ///
    /// This method is particularly useful to access the fully typed version of the `EndpointParameter`.
    ///
    /// - Parameter exporter: The `InterfaceExporter` to export the parameters on.
    /// - Returns: The result of the individual `InterfaceExporter.exporterParameter(...)` calls.
    @discardableResult
    func exportParameters<I: InterfaceExporter>(on exporter: I) -> [I.ParameterExportOutput]
}

protocol _AnyEndpoint: AnyEndpoint {
    /// Internal method which is called to call the `InterfaceExporter.export(...)` method on the given `exporter`.
    ///
    /// - Parameter exporter: The `InterfaceExporter` used to export the given `Endpoint`
    /// - Returns: Whatever the export method of the `InterfaceExporter` returns (which equals to type `EndpointExporterOutput`) is returned here.
    @discardableResult
    func exportEndpoint<I: InterfaceExporter>(on exporter: I) -> I.EndpointExportOutput
}


/// Models a single Endpoint which is identified by its PathComponents and its operation
public struct Endpoint<H: Handler>: _AnyEndpoint {
    private let sharedRepository: SharedRepository
    
    init(sharedRepository: SharedRepository) {
        self.sharedRepository = sharedRepository
    }
    
    public subscript<S>(_ type: S.Type) -> S where S: KnowledgeSource {
        get { sharedRepository[type] }
        nonmutating set { sharedRepository[type] = newValue }
    }
    
    public func request<S>(_ type: S.Type) throws -> S where S: KnowledgeSource {
        try self.sharedRepository.request(type)
    }

    /// Provides the ``EndpointParameters`` that correspond to the ``Parameter``s defined on the ``Handler`` of this ``Endpoint``
    public var parameters: [AnyEndpointParameter] {
        self[EndpointParameters.self]
    }

    @discardableResult
    public func exportParameters<I: InterfaceExporter>(on exporter: I) -> [I.ParameterExportOutput] {
        self[EndpointParameters.self].exportParameters(on: exporter)
    }
}

extension Endpoint {
    /// The ``Handler`` responsible for this ``Endpoint``.
    ///
    /// This is just a shortcut for ``EndpointSource/handler``. which can be accessed via the ``SharedRepository``.
    public var handler: H {
        self[EndpointSource<H>.self].handler
    }
}

extension Endpoint {
    func exportEndpoint<I: InterfaceExporter>(on exporter: I) -> I.EndpointExportOutput {
        if let blobEndpoint = self as? BlobEndpoint {
            return blobEndpoint.exportBlobEndpoint(on: exporter)
        } else {
            return exporter.export(self)
        }
    }
}

private protocol BlobEndpoint {
    func exportBlobEndpoint<I: InterfaceExporter>(on exporter: I) -> I.EndpointExportOutput
}

extension Endpoint: BlobEndpoint where H.Response.Content == Blob {
    func exportBlobEndpoint<I: InterfaceExporter>(on exporter: I) -> I.EndpointExportOutput {
        exporter.export(blob: self)
    }
}

extension Endpoint: CustomDebugStringConvertible {
    public var debugDescription: String {
        String(describing: self.handler)
    }
}

extension Endpoint: CustomStringConvertible {
    public var description: String {
        self[HandlerDescription.self].rawValue
    }
}
