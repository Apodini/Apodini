//
// Created by Andi on 22.11.20.
//

import class Vapor.Application
import protocol NIO.EventLoop
import protocol FluentKit.Database

/// The Protocol any Exporter Request type must conform to
protocol ExporterRequest {}

/// When your `ExporterRequest` conforms to this protocol, it indicates that it delivers
/// its own `EventLoop` out of the box. Having that conformance you can use a shorthand
/// `EndpointRequestHandler.handleRequest(...)` method on without specifying an `EventLoop`.
protocol WithEventLoop {
    var eventLoop: EventLoop { get }
}

func null<T>(_ type: T.Type = T.self) -> T? {
    T?(nil)
}

/// Any Apodini Interface Exporter must conform to this protocol.
protocol InterfaceExporter {
    /// Defines the type of the Request the exporter uses.
    associatedtype ExporterRequest: Apodini.ExporterRequest
    /// Defines the return type of the `export` method. The return type is currently unused.
    associatedtype EndpointExportOutput = Void
    /// Defines the return ype of the `exportParameter` method. For more details see `exportParameter(...)`
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
    func finishedExporting(_ webService: WebServiceModel) {}
    func exportParameter<Type: Codable>(_ parameter: EndpointParameter<Type>) {}

    func accept(_ visitor: InterfaceExporterVisitor) {
        visitor.visit(exporter: self)
    }
}

protocol InterfaceExporterVisitor {
    func visit<I: InterfaceExporter>(exporter: I)
}

struct AnyInterfaceExporter {
    private let _accept: (_ visitor: InterfaceExporterVisitor) -> Void

    init<I: InterfaceExporter>(_ exporter: I) {
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
