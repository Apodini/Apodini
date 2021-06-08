//
// Created by Andreas Bauer on 22.11.20.
//

import protocol NIO.EventLoop

/// This is the base protocol shared by any Exporter type supported by Apodini.
/// Currently the following two types are supported:
/// - `InterfaceExporter`: This type should be used for Exporters serving an accessible WebService
/// - `StaticInterfaceExporter`: This type should be used for Exporters service a representation of the WebService (e.g. documentation)
public protocol BaseInterfaceExporter {
    /// Defines the return type of the `export` method. The return type is currently unused.
    associatedtype EndpointExportOutput = Void
    /// Defines the return type of the `exportParameter` method. For more details see `exportParameter(...)`
    associatedtype ParameterExportOutput = Void

    /// This property can be used to define the `ParameterNamespace` for `EndpointParameter`s as allowed by the type of Exporter.
    /// This property is optional to implement and will default to the most strict namespace `.global`,
    /// enforcing Parameter names to be unique across all different `ParameterType`s.
    static var parameterNamespace: [ParameterNamespace] { get }

    /// This method is called for every `Endpoint` on start up, which must be exporter
    /// by the `InterfaceExporter`.
    ///
    /// - Parameter endpoint: The `Endpoint` which is to be exported.
    /// - Returns: `EndpointExportOutput` which is defined by the `InterfaceExporter`.
    func export<H: Handler>(_ endpoint: Endpoint<H>) -> EndpointExportOutput

    /// This optional method can be defined to export a `EndpointParameter`.
    /// It is called for every `EndpointParameter` on an `Endpoint` when calling `Endpoint.exportParameters(...)`.
    /// `Endpoint.exportParameters(...)` returns an array of `ParameterExportOutput`, being what is returned by this method.
    ///
    /// - Parameter parameter:
    /// - Returns: `ParameterExportOutput` which is defined by the `InterfaceExporter`
    func exportParameter<Type: Codable>(_ parameter: EndpointParameter<Type>) -> ParameterExportOutput

    /// This method is called once all `Endpoint`s are exported, meaning after `export` was called
    /// for every `Endpoint` on the `WebService`.
    /// A `InterfaceExporter` is not required to implement that method.
    ///
    /// - Parameter webService: A model representing the exported `WebService`
    func finishedExporting(_ webService: WebServiceModel)
}

// Providing empty default implementations for optional methods
public extension BaseInterfaceExporter {
    /// Default empty implementation as method is optionally to implement
    func exportParameter<Type: Codable>(_ parameter: EndpointParameter<Type>) {}
    /// Default empty implementation as method is optionally to implement
    func finishedExporting(_ webService: WebServiceModel) {}
}


/// Any Interface Exporter creating an accessible WebService must conform to this protocol.
public protocol InterfaceExporter: BaseInterfaceExporter {
    /// Defines the type of the Request the exporter uses.
    associatedtype ExporterRequest: Apodini.ExporterRequest

    /// This method is called on `EndpointParameter` injection to retrieve the value from the given `ExporterRequest`.
    /// Be aware that the generic `Type` holds the Wrapped type for `Optional`s (see `EndpointParameter`).
    ///
    /// If the value couldn't be found on the `ExporterRequest` for the given `EndpointParameter`, the `interfaceExporter`
    /// must return `nil`. Checking for required parameters is done automatically.
    ///
    /// If the content type of the `ExporterRequest` supports "explicit nil", like JSON does with `null`,
    /// you can signal that using `Type?(nil)`..
    ///
    /// - Parameters:
    ///   - parameter: The `EndpointParameter` describing the parameter for which the value should be retrieved.
    ///   - request: The `ExporterRequest` as defined by the `InterfaceExporter`
    /// - Returns: The retrieved value, nil if `ExporterRequest` didn't contain a value for the given `EndpointParameter`
    ///     or "explicit nil" using `Type?(nil)`.
    /// - Throws: Any Apodini Error or any other error happening while decoding.
    func retrieveParameter<Type: Decodable>(_ parameter: EndpointParameter<Type>, for request: ExporterRequest) throws -> Type??
}

public extension BaseInterfaceExporter {
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


/// Any InterfaceExporter creating a representation of the WebService must conform to this protocol.
///
/// Such exporters do not actively create a accessible WebService themselves but rather a static representation
/// of the WebService (e.g. a Endpoint serving documentation of the WebService).
public protocol StaticInterfaceExporter: BaseInterfaceExporter {}

extension StaticInterfaceExporter {
    func accept(_ visitor: InterfaceExporterVisitor) {
        visitor.visit(staticExporter: self)
    }
}
