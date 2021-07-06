//
//  InterfaceExporterLegacyStrategy.swift
//  
//
//  Created by Max Obermeier on 06.07.21.
//

import Apodini

/// An ``EndpointDecodingStrategy`` that uses a ``ParameterDecodingStrategy`` which
/// refers to the given `exporter`'s ``LegacyInterfaceExporter/retrieveParameter(_:for:)``
/// method to retrieve the `parameter`'s value.
public struct InterfaceExporterLegacyStrategy<IE: LegacyInterfaceExporter>: EndpointDecodingStrategy {
    private let exporter: IE
    
    public init(_ exporter: IE) {
        self.exporter = exporter
    }
    
    public func strategy<Element>(for parameter: EndpointParameter<Element>)
        -> AnyParameterDecodingStrategy<Element, IE.ExporterRequest> where Element: Decodable, Element: Encodable {
        InterfaceExporterLegacyParameterStrategy<IE, Element>(parameter: parameter, exporter: exporter).typeErased
    }
}
