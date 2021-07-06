//
//  InterfaceExporterLegacyParameterStrategy.swift
//  
//
//  Created by Max Obermeier on 06.07.21.
//

import Foundation
import ApodiniUtils
import Apodini

struct InterfaceExporterLegacyParameterStrategy<IE: LegacyInterfaceExporter, E: Codable>: ParameterDecodingStrategy {
    let parameter: EndpointParameter<E>
    let exporter: IE
    
    func decode(from input: IE.ExporterRequest) throws -> E {
        let result = try exporter.retrieveParameter(parameter, for: input)
        
        switch result {
        case let .some(.some(value)):
            return value
        case .some(.none):
            throw DecodingError.valueNotFound(E.self, DecodingError.Context(
                codingPath: [],
                debugDescription: "Exporter \(IE.self) encountered an explicit 'nil' value for \(parameter) in \(input).",
                underlyingError: nil))
        case .none:
            throw DecodingError.keyNotFound(parameter.name, DecodingError.Context(
                codingPath: [],
                debugDescription: "Exporter \(IE.self) could not decode a value for \(parameter) from \(input).",
                underlyingError: nil))
        }
    }
}
