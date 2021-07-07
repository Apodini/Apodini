//
//  LegacyInterfaceExporter.swift
//  
//
//  Created by Max Obermeier on 28.06.21.
//

import Apodini


/// A legacy version of the `InterfaceExporter` protocol, which relies on ``retrieveParameter(_:for:)``
/// and ``InterfaceExporterLegacyStrategy`` for decoding input instead of a proper ``DecodingStrategy``.
public protocol LegacyInterfaceExporter: InterfaceExporter {
    /// Defines the type of the Request the exporter uses.
    associatedtype ExporterRequest

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

public extension LegacyInterfaceExporter {
    /// The default implementation for exporting Apodini `Blob` for legacy exporters is to export them as a normal endpoint.
    func export<H>(blob endpoint: Endpoint<H>) -> EndpointExportOutput where H: Handler, H.Response.Content == Blob {
        export(endpoint)
    }
}
