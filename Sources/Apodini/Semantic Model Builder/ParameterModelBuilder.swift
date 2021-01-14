//
// Created by Andi on 05.01.21.
//

extension Handler {
    func buildParametersModel() -> [AnyEndpointParameter] {
        let builder = ParameterModelBuilder(from: self)
            .build()
        return builder.parameters
    }
}

private class ParameterModelBuilder<H: Handler>: RequestInjectableVisitor {
    let orderedRequestInjectables: [(String, RequestInjectable)]
    let requestInjectables: [String: RequestInjectable]
    var currentLabel: String?

    var parameters: [AnyEndpointParameter] = []

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

        let endpointParameter: AnyEndpointParameter
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
    ) -> AnyEndpointParameter
}

// MARK: Parameter Model
extension Parameter: EncodeOptionalEndpointParameter where Element: ApodiniOptional, Element.Member: Codable {
    func createParameterWithWrappedType(
        name: String,
        label: String,
        necessity: Necessity
    ) -> AnyEndpointParameter {
        var `default`: (() -> Element.Member)?
        if let defaultValue = self.defaultValue, defaultValue().optionalInstance != nil {
            `default` = {
                guard let member = defaultValue().optionalInstance else {
                    fatalError("Could unwrap the value during startup. Default @Parameter values MUST NOT change.")
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
