//
// Created by Andi on 05.01.21.
//

extension Handler {
    func buildParametersModel() -> [_AnyEndpointParameter] {
        let builder = ParameterModelBuilder(from: self)
            .build()
        return builder.parameters
    }
}

private class ParameterModelBuilder<H: Handler>: RequestInjectableVisitor {
    let orderedRequestInjectables: [(String, RequestInjectable)]
    let requestInjectables: [String: RequestInjectable]
    var currentLabel: String?

    var parameters: [_AnyEndpointParameter] = []

    init(from handler: H) {
        let orderedRequestInjectables = handler.extractRequestInjectables()
        self.orderedRequestInjectables = orderedRequestInjectables
        var requestInjectables = [String: RequestInjectable]()
        for (label, injectable) in orderedRequestInjectables {
            requestInjectables[label] = injectable
        }
        self.requestInjectables = requestInjectables
    }

    func build() -> Self {
        for (label, requestInjectable) in orderedRequestInjectables {
            currentLabel = label
            requestInjectable.accept(self)
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

        if let existing = parameters.first(where: { $0.id == parameter.id }) {
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

        parameters.append(endpointParameter)
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
extension Parameter: EncodeOptionalEndpointParameter where Element: ApodiniOptional, Element.Member: Codable {
    func createParameterWithWrappedType(
        name: String,
        label: String,
        necessity: Necessity
    ) -> _AnyEndpointParameter {
        var `default`: (() -> Element.Member)?
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
        
        return EndpointParameter<Element.Member>(
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
