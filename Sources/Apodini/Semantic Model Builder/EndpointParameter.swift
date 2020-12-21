//
//  EndpointParameter.swift
//  
//
//  Created by Lorena Schlesinger on 06.12.20.
//

import Foundation

struct EndpointParameter {
    let id: UUID
    let name: String?
    let label: String
    let contentType: Codable.Type
    let options: PropertyOptionSet<ParameterOptionNameSpace>
    let parameterType: EndpointParameterType
    
    /// `@Parameter` categorization needed for certain interface exporters (e.g., HTTP-based).
    enum EndpointParameterType {
        case lightweight
        case content
        case path
    }

    init(id: UUID, name: String?, label: String, contentType: Codable.Type, options: PropertyOptionSet<ParameterOptionNameSpace>) {
        self.id = id
        self.name = name
        self.label = label
        self.contentType = contentType
        self.options = options

        let httpOption = options.option(for: PropertyOptionKey.http)
        switch httpOption {
        case .path:
            precondition(contentType is LosslessStringConvertible.Type, "Invalid explicit option .path for parameter \(name ?? label). Option is only available for wrapped properties conforming to \(LosslessStringConvertible.self).")
            parameterType = .path
        case .query:
            precondition(contentType is LosslessStringConvertible.Type, "Invalid explicit option .query for parameter \(name ?? label). Option is only available for wrapped properties conforming to \(LosslessStringConvertible.self).")
            parameterType = .lightweight
        case .body:
            parameterType = .content
        default:
            parameterType = contentType is LosslessStringConvertible.Type ? .lightweight : .content
        }
    }
}

class ParameterBuilder: RequestInjectableVisitor {
    let requestInjectables: [String: RequestInjectable]
    var currentLabel: String?

    var parameters: [EndpointParameter] = []

    init<C: Handler>(from component: C) {
        self.requestInjectables = component.extractRequestInjectables()
    }

    func build() {
        for (label, requestInjectable) in requestInjectables {
            currentLabel = label
            requestInjectable.accept(self)
        }
        currentLabel = nil
    }

    func visit<Element>(_ parameter: Parameter<Element>) {
        guard let label = currentLabel else {
            preconditionFailure("EndpointParameter visited a Parameter where current label wasn't set. Something must have been called out of order!")
        }

        let endpointParameter = EndpointParameter(
                id: parameter.id,
                name: parameter.name,
                label: label,
                contentType: Element.self,
                options: parameter.options
        )

        parameters.append(endpointParameter)
    }
}

struct PathComponentAnalyzer: PathBuilder {
    struct PathParameterAnalyzingResult {
        var parameterMode: HTTPParameterMode?
    }

    var result: PathParameterAnalyzingResult?

    mutating func append<T>(_ parameter: Parameter<T>) {
        result = PathParameterAnalyzingResult(
                parameterMode: parameter.option(for: .http)
        )
    }

    mutating func append(_ string: String) {}

    /// This function does two things:
    ///   * First it checks if the given `_PathComponent` is of type Parameter. If it is it returns
    ///     a `PathParameterAnalyzingResult` otherwise it returns nil.
    ///   * Secondly it retrieves the .http ParameterOption for the Parameter which is stored in the `PathParameterAnalyzingResult`
    static func analyzePathComponentForParameter(_ pathComponent: _PathComponent) -> PathParameterAnalyzingResult? {
        var analyzer = PathComponentAnalyzer()
        pathComponent.append(to: &analyzer)
        return analyzer.result
    }
}
