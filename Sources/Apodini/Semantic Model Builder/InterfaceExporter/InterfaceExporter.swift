//
// Created by Andreas Bauer on 22.11.20.
//

import protocol NIO.EventLoop

/// This is the base protocol shared by any Exporter type supported by Apodini. Any Interface Exporter
/// creating an accessible WebService or a WebService specification document must conform to this protocol.
public protocol InterfaceExporter {
    /// Defines the return type of the `export` method. The return type is currently unused.
    associatedtype EndpointExportOutput = Void
    /// Defines the return type of the `exportParameter` method. For more details see `exportParameter(...)`
    associatedtype ParameterExportOutput = Void

    /// This property can be used to define the `ParameterNamespace` for `EndpointParameter`s as allowed by the type of Exporter.
    /// This property is optional to implement and will default to the most strict namespace `.global`,
    /// enforcing Parameter names to be unique across all different `ParameterType`s.
    static var parameterNamespace: [ParameterNamespace] { get }

    /// This method is called for every `Endpoint` on start up, which must be exported
    /// by the `InterfaceExporter` where the `Endpoint`'s response is no ``Blob``.
    ///
    /// - Parameter endpoint: The `Endpoint` which is to be exported.
    /// - Returns: `EndpointExportOutput` which is defined by the `InterfaceExporter`.
    func export<H: Handler>(_ endpoint: Endpoint<H>) -> EndpointExportOutput
    
    /// This method is called for every `Endpoint` on start up, which must be exporter
    /// by the `InterfaceExporter` where the `Endpoint`'s response is ``Blob``
    ///
    /// - Parameter endpoint: The `Endpoint` which is to be exported.
    /// - Returns: `EndpointExportOutput` which is defined by the `InterfaceExporter`.
    func export<H: Handler>(blob endpoint: Endpoint<H>) -> EndpointExportOutput where H.Response.Content == Blob

    /// This optional method can be defined to export a `EndpointParameter`.
    /// It is called for every `EndpointParameter` on an `Endpoint` when calling `Endpoint.exportParameters(...)`.
    /// `Endpoint.exportParameters(...)` returns an array of `ParameterExportOutput`, being what is returned by this method.
    ///
    /// - Parameter parameter:
    /// - Returns: `ParameterExportOutput` which is defined by the `InterfaceExporter`
    func exportParameter<Type: Decodable>(_ parameter: EndpointParameter<Type>) -> ParameterExportOutput

    /// This method is called once all `Endpoint`s are exported, meaning after `export` was called
    /// for every `Endpoint` on the `WebService`.
    /// A `InterfaceExporter` is not required to implement that method.
    ///
    /// - Parameter webService: A model representing the exported `WebService`
    func finishedExporting(_ webService: WebServiceModel)
}

// Providing empty default implementations for optional methods
public extension InterfaceExporter {
    /// Default empty implementation as method is optionally to implement
    func exportParameter<Type: Decodable>(_ parameter: EndpointParameter<Type>) {}
    /// Default empty implementation as method is optionally to implement
    func finishedExporting(_ webService: WebServiceModel) {}
}


public extension InterfaceExporter {
    /// Defines the default `.global` namespace for every interface exporter.
    static var parameterNamespace: [ParameterNamespace] {
        // default namespace (and most strictest namespace)
        // forces parameter names to be unique across all parameter types
        .global
    }
}


// MARK: Interface Exporter Visitor
extension InterfaceExporter {
    func accept(_ visitor: InterfaceExporterVisitor) {
        visitor.visit(exporter: self)
    }
}
