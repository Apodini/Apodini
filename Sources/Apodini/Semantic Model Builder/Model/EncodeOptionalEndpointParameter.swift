//
//  File.swift
//  
//
//  Created by Nityananda on 07.01.21.
//

protocol EncodeOptionalEndpointParameter {
    func createParameterWithWrappedType(
        name: String,
        label: String,
        necessity: Necessity
    ) -> AnyEndpointParameter
}

// MARK: - Parameter+EncodeOptionalEndpointParameter

extension Parameter: EncodeOptionalEndpointParameter where Element: ApodiniOptional, Element.Member: Codable {
    func createParameterWithWrappedType(
        name: String,
        label: String,
        necessity: Necessity
    ) -> AnyEndpointParameter {
        let defaultValue = self.defaultValue?.optionalInstance
        
        return EndpointParameter<Element.Member>(
            id: self.id,
            name: name,
            label: label,
            nilIsValidValue: true,
            necessity: necessity,
            options: self.options,
            defaultValue: defaultValue
        )
    }
}
