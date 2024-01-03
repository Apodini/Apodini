//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import ApodiniUtils


extension Handler {
    func buildParametersModel() -> [any _AnyEndpointParameter] {
        let builder = ParameterModelBuilder(from: self)
            .build()
        return builder.parametersInternal.uniqued(with: \.id)
    }
}

private class ParameterModelBuilder<H: Handler>: AnyParameterVisitor {
    let orderedParameters: [(String, any AnyParameter)]
    let parameters: [String: any AnyParameter]
    var currentLabel: String?

    var parametersInternal: [any _AnyEndpointParameter] = []

    init(from handler: H) {
        let orderedParameters = handler.extractParameters()
        self.orderedParameters = orderedParameters
        var parameters = [String: any AnyParameter]()
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

        let endpointParameter: any _AnyEndpointParameter
        if let optionalParameter = parameter as? any EncodeOptionalEndpointParameter {
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
                originalPropertyType: Element.self,
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
    ) -> any _AnyEndpointParameter // TODO some?
}

// MARK: Parameter Model
extension Parameter: EncodeOptionalEndpointParameter where Element: OptionalProtocol, Element.Wrapped: Codable {
    func createParameterWithWrappedType(
        name: String,
        label: String,
        necessity: Necessity
    ) -> any _AnyEndpointParameter {
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
            originalPropertyType: Element.self,
            nilIsValidValue: true,
            necessity: necessity,
            options: self.options,
            defaultValue: `default`
        )
    }
}


// MARK: Helpers

extension Sequence {
    func uniqued<H: Hashable>(with id: KeyPath<Element, H>) -> [Element] {
        var set = Set<H>()
        return filter { set.insert($0[keyPath: id]).inserted }
    }
}
