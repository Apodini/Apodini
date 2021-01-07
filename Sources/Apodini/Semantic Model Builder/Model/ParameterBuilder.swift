//
//  File.swift
//  
//
//  Created by Nityananda on 07.01.21.
//

class ParameterBuilder: RequestInjectableVisitor {
    let orderedRequestInjectables: [(String, RequestInjectable)]
    let requestInjectables: [String: RequestInjectable]
    var currentLabel: String?
    
    var parameters: [AnyEndpointParameter] = []
    
    init<H: Handler>(from handler: H) {
        let orderedRequestInjectables = handler.extractRequestInjectables()
        self.orderedRequestInjectables = orderedRequestInjectables
        var requestInjectables = [String: RequestInjectable]()
        for (label, injectable) in orderedRequestInjectables {
            requestInjectables[label] = injectable
        }
        self.requestInjectables = requestInjectables
    }
    
    func build() {
        for (label, requestInjectable) in orderedRequestInjectables {
            currentLabel = label
            requestInjectable.accept(self)
        }
        currentLabel = nil
    }
    
    func visit<Element>(_ parameter: Parameter<Element>) {
        guard let label = currentLabel else {
            preconditionFailure("EndpointParameter visited a Parameter where current label wasn't set. Something must have been called out of order!")
        }
        
        var trimmedLabel = label
        if trimmedLabel.first == "_" {
            trimmedLabel.removeFirst()
        }
        
        let endpointParameter: AnyEndpointParameter
        if let optionalParameter = parameter as? EncodeOptionalEndpointParameter {
            endpointParameter = optionalParameter.createParameterWithWrappedType(
                name: parameter.name ?? trimmedLabel,
                label: label,
                necessity: .optional
            )
        } else {
            endpointParameter = EndpointParameter<Element>(
                id: parameter.id,
                name: parameter.name ?? trimmedLabel,
                label: label,
                nilIsValidValue: false,
                necessity: parameter.defaultValue == nil ? .required : .optional, // a parameter is optional when a defaultValue is defined
                options: parameter.options,
                defaultValue: parameter.defaultValue
            )
        }
        
        parameters.append(endpointParameter)
    }
}
