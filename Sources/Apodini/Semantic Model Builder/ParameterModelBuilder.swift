//
// Created by Andreas Bauer on 05.01.21.
//

import ApodiniUtils


extension Handler {
    func buildParametersModel() -> [_AnyEndpointParameter] {
        let builder = ParameterModelBuilder(from: self)
            .build()
        return builder.parametersInternal
    }
}

private class ParameterModelBuilder<H: Handler>: AnyParameterVisitor {
    let orderedParameters: [(String, AnyParameter)]
    let parameters: [String: AnyParameter]
    var currentLabel: String?

    var parametersInternal: [_AnyEndpointParameter] = []

    init(from handler: H) {
        let orderedParameters = handler.extractParameters()
        self.orderedParameters = orderedParameters
        var parameters = [String: AnyParameter]()
        for (label, parameter) in orderedParameters {
            parameters[label] = parameter
        }
        self.parameters = parameters
    }

    func build() -> Self {
        for (label, parameter) in orderedParameters {
            currentLabel = label
            parameter.accept(self)
        }
        currentLabel = nil
        return self
    }

    func visit<Element>(_ parameter: Parameter<Element>) {
        guard let label = currentLabel else {
            preconditionFailure("EndpointParameter visited a Parameter where current label wasn't set. Something must have been called out of order!")
        }

        var trimmedLabel = label
        if trimmedLabel.first == "_" {
            trimmedLabel.removeFirst()
        }

        if let existing = parametersInternal.first(where: { $0.id == parameter.id }) {
            preconditionFailure("""
                                When parsing Parameter '\(parameter.name ?? trimmedLabel)' on Handler \(H.self) we encountered an UUID collision\
                                with the existing Parameter '\(existing.name)'.
                                """)
        }

        let endpointParameter: _AnyEndpointParameter
        if let optionalParameter = parameter as? EncodeOptionalEndpointParameter {
            endpointParameter = optionalParameter.createParameterWithWrappedType(
                name: parameter.name ?? trimmedLabel,
                label: label,
                necessity: .optional
            )
        } else {
            endpointParameter = EndpointParameter(
                id: parameter.id,
                name: parameter.name ?? trimmedLabel,
                label: label,
                nilIsValidValue: false,
                necessity: parameter.defaultValue != nil ? .optional : .required, // a parameter is optional when a defaultValue is defined
                options: parameter.options,
                defaultValue: parameter.defaultValue
            )
        }

        parametersInternal.append(endpointParameter)
    }
}

private protocol EncodeOptionalEndpointParameter {
    func createParameterWithWrappedType(
        name: String,
        label: String,
        necessity: Necessity
    ) -> _AnyEndpointParameter
}

// MARK: Parameter Model
extension Parameter: EncodeOptionalEndpointParameter where Element: OptionalProtocol, Element.Wrapped: Codable {
    func createParameterWithWrappedType(
        name: String,
        label: String,
        necessity: Necessity
    ) -> _AnyEndpointParameter {
        var `default`: (() -> Element.Wrapped)?
        if let defaultValue = self.defaultValue, let originalDefaultValue = defaultValue().optionalInstance {
            `default` = {
                guard let member = defaultValue().optionalInstance else {
                    fatalError(
                        """
                        Encountered an internal Apodini error: Default values of `@Parameter`s are constants.
                        The developer using Apodini should make sure they do not change their value during runtime.
                        The orginal default value for the @Parameter was \(originalDefaultValue) and now it is nil.
                        """
                    )
                }
                return member
            }
        }
        
        return EndpointParameter<Element.Wrapped>(
            id: self.id,
            name: name,
            label: label,
            nilIsValidValue: true,
            necessity: necessity,
            options: self.options,
            defaultValue: `default`
        )
    }
}
