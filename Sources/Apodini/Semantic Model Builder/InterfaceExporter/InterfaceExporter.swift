//
// Created by Andi on 22.11.20.
//

@_implementationOnly import class Vapor.Application
import protocol NIO.EventLoop
import protocol FluentKit.Database

/// The Protocol any Exporter Request type must conform to
protocol ExporterRequest: Reducible {}

/// When your `ExporterRequest` conforms to this protocol, it indicates that it delivers
/// its own `EventLoop` out of the box. Having that conformance you can use a shorthand
/// `EndpointRequestHandler.handleRequest(...)` method on without specifying an `EventLoop`.
protocol WithEventLoop {
    var eventLoop: EventLoop { get }
}

/// This is the base protocol shared by any Exporter type supported by Apodini.
/// Currently the following two types are supported:
/// - `InterfaceExporter`: This type should be used for Exporters serving an accessible WebService
/// - `StaticInterfaceExporter`: This type should be used for Exporters service a representation of the WebService (e.g. documentation)
protocol BaseInterfaceExporter {
    /// Defines the return type of the `export` method. The return type is currently unused.
    associatedtype EndpointExportOutput = Void
    /// Defines the return type of the `exportParameter` method. For more details see `exportParameter(...)`
    associatedtype ParameterExportOutput = Void

    init(_ app: Application)

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

    /// Internal method used with the `InterfaceExporterVisitor`.
    /// A proper implementation is provided by default for any exporter type.
    /// - Parameter visitor: The instance of the `InterfaceExporterVisitor`
    func accept(_ visitor: InterfaceExporterVisitor)
}

// Providing empty default implementations for Parameters
extension BaseInterfaceExporter {
    func exportParameter<Type: Codable>(_ parameter: EndpointParameter<Type>) {}
    func finishedExporting(_ webService: WebServiceModel) {}
}


/// Any Interface Exporter creating an accessible WebService must conform to this protocol.
protocol InterfaceExporter: BaseInterfaceExporter {
    /// Defines the type of the Request the exporter uses.
    associatedtype ExporterRequest: Apodini.ExporterRequest

    /// This method is called on `EndpointParameter` injection to retrieve the value from the given `ExporterRequest`.
    /// Be aware that the generic `Type` holds the Wrapped type for `Optional`s (see `EndpointParameter`).
    ///
    /// If the value couldn't be found on the `ExporterRequest` for the given `EndpointParameter`, the `interfaceExporter`
    /// must return `nil`. Checking for required parameters is done automatically.
    ///
    /// If the content type of the `ExporterRequest` supports "explicit nil", like JSON does with `null`,
    /// you can signal that using `Type?(nil)` (or using `Optional.null` as abbreviation).
    ///
    /// - Parameters:
    ///   - parameter: The `EndpointParameter` describing the parameter for which the value should be retrieved.
    ///   - request: The `ExporterRequest` as defined by the `InterfaceExporter`
    /// - Returns: The retrieved value, nil if `ExporterRequest` didn't contain a value for the given `EndpointParameter`
    ///     or "explicit nil" using `Type?(nil)`.
    /// - Throws: Any Apodini Error or any other error happening while decoding.
    func retrieveParameter<Type: Decodable>(_ parameter: EndpointParameter<Type>, for request: ExporterRequest) throws -> Type??
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
/// of the WebService is created (e.g. a Endpoint serving documentation of the WebService).
protocol StaticInterfaceExporter: BaseInterfaceExporter {}

extension StaticInterfaceExporter {
    func accept(_ visitor: InterfaceExporterVisitor) {
        visitor.visit(staticExporter: self)
    }
}


protocol InterfaceExporterVisitor {
    func visit<I: InterfaceExporter>(exporter: I)
    func visit<I: StaticInterfaceExporter>(staticExporter: I)
}


struct AnyInterfaceExporter {
    private let _accept: (_ visitor: InterfaceExporterVisitor) -> Void

    init<I: BaseInterfaceExporter>(_ exporter: I) {
        _accept = exporter.accept
    }

    func accept(_ visitor: InterfaceExporterVisitor) {
        _accept(visitor)
    }
}

extension Array where Element == AnyInterfaceExporter {
    func acceptAll(_ visitor: InterfaceExporterVisitor) {
        for exporter in self {
            exporter.accept(visitor)
        }
    }
}
