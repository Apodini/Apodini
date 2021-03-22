//
//  File.swift
//  
//
//  Created by Eldi Cano on 22.03.21.
//

import Foundation

struct ServiceParameter: Codable {

    let name: String
    let necessity: Necessity
    let type: ParameterType
    let nilIsValidValue: Bool
    let schemaReference: SchemaReference
}

extension Array where Element == AnyEndpointParameter {

    func serviceParameters(with builder: inout SchemaBuilder) -> [ServiceParameter] {
        map {
            let reference = builder.build(for: $0.propertyType, root: false) ?? .empty
            return ServiceParameter(
                name: $0.name,
                necessity: $0.necessity,
                type: $0.parameterType,
                nilIsValidValue: $0.nilIsValidValue,
                schemaReference: reference
            )
        }
    }
}
