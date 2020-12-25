//
//  EndpointParameter.swift
//  
//
//  Created by Lorena Schlesinger on 06.12.20.
//

import Foundation

/// `@Parameter` categorization needed for certain interface exporters (e.g., HTTP-based).
enum EndpointParameterType {
    case lightweight
    case content
    case path
}

/// Defines the necessity of a `EndpointParameter`
enum Necessity {
    case required
    case optional
}

protocol EndpointParameterVisitor {
    associatedtype Output
    func visit<Element: Codable>(parameter: EndpointParameter<Element>) -> Output
}

protocol EndpointParameterThrowingVisitor {
    associatedtype Output
    func visit<Element: Codable>(parameter: EndpointParameter<Element>) throws -> Output
}

/// Describes a type erasured `EndpointParameter`
protocol AnyEndpointParameter {
    /// The `UUID` which uniquely identifies the given `AnyEndpointParameter`.
    var id: UUID { get }
    var pathId: String { get }
    /// This property holds the name as defined by the user.
    /// Either its a custom defined name or the property name of the `propertyWrapper`
    /// (though removing the leading '_' which is typical for `propertyWrapper`s)
    var name: String { get }
    /// This is the label of the property as its delivered from `Mirror`.
    ///
    /// For the following declaration
    /// ```
    /// @Parameter var name: String
    /// ```
    /// this property will hold "_name".
    var label: String { get }
    /// Defines the property type of the `Parameter` declaration in a statically accessible way.
    /// Be aware that for optional `Parameter` this property holds the wrapped type of the `Optional`.
    /// See `accept(...)` to access the type in a generic way.
    ///
    /// For the following declaration
    /// ```
    /// @Parameter var name: String?
    /// ```
    /// this property holds `String.Type` and not `Optional<String>.self`.
    ///
    /// Use the `necessity` property to check if a given `AnyEndpointParameter` is a optional parameter.
    var propertyType: Codable.Type { get }
    /// Holds the options as defined by the user.
    var options: PropertyOptionSet<ParameterOptionNameSpace> { get }
    /// Defines the `Necessity` of the parameter.
    var necessity: Necessity { get }
    /// Defines the `EndpointParameterType` of the parameter.
    var parameterType: EndpointParameterType { get }
    var typeErasuredDefaultValue: Any? { get }

    func accept<Visitor: EndpointParameterVisitor>(_ visitor: Visitor) -> Visitor.Output
    func accept<Visitor: EndpointParameterThrowingVisitor>(_ visitor: Visitor) throws -> Visitor.Output

    /// This method is used to call `InterfaceExporter.retrieveParameter(...)` on
    /// the given `InterfaceExporter`
    ///
    /// - Parameter exporter: The `InterfaceExporter`.
    /// - Returns: Returns what `InterfaceExporter.retrieveParameter(...)` returns.
    func exportParameter<I: InterfaceExporter>(on exporter: I) -> I.ParameterExportOutput
}

/// Models a `Parameter`. See `AnyEndpointParameter` for detailed documentation.
///
/// Be aware that for optional `Parameter` the generic `Type` holds the wrapped type of the `Optional`.
/// For the following declaration
/// ```
/// @Parameter var name: String?
/// ```
/// the generic holds `String.Type` and not `Optional<String>.self`.
/// Use the `necessity` property to check if a given `EndpointParameter` is a optional parameter.
struct EndpointParameter<Type: Codable>: AnyEndpointParameter {
    let id: UUID
    var pathId: String {
        if parameterType != .path {
            fatalError("Cannot access EndpointParameter.pathId when the parameter type isn't .path!")
        }
        return ":\(id)"
    }
    let name: String
    let label: String
    let propertyType: Codable.Type
    let options: PropertyOptionSet<ParameterOptionNameSpace>
    let necessity: Necessity
    let parameterType: EndpointParameterType

    let defaultValue: Type?
    var typeErasuredDefaultValue: Any? {
        defaultValue
    }

    init(id: UUID,
         name: String,
         label: String,
         necessity: Necessity,
         options: PropertyOptionSet<ParameterOptionNameSpace>,
         defaultValue: Type? = nil
    ) {
        self.id = id
        self.name = name
        self.label = label
        self.propertyType = Type.self
        self.options = options
        self.necessity = necessity
        self.defaultValue = defaultValue

        let httpOption = options.option(for: PropertyOptionKey.http)
        switch httpOption {
        case .path:
            precondition(Type.self is LosslessStringConvertible.Type, "Invalid explicit option .path for parameter \(name). Option is only available for wrapped properties conforming to \(LosslessStringConvertible.self).")
            parameterType = .path
        case .query:
            precondition(Type.self is LosslessStringConvertible.Type, "Invalid explicit option .query for parameter \(name). Option is only available for wrapped properties conforming to \(LosslessStringConvertible.self).")
            parameterType = .lightweight
        case .body:
            parameterType = .content
        default:
            parameterType = Type.self is LosslessStringConvertible.Type ? .lightweight : .content
        }
    }

    func accept<Visitor: EndpointParameterVisitor>(_ visitor: Visitor) -> Visitor.Output {
        visitor.visit(parameter: self)
    }
    func accept<Visitor: EndpointParameterThrowingVisitor>(_ visitor: Visitor) throws -> Visitor.Output {
        try visitor.visit(parameter: self)
    }

    func exportParameter<I: InterfaceExporter>(on exporter: I) -> I.ParameterExportOutput {
        exporter.exportParameter(self)
    }
}

// MARK: Endpoint Parameter
extension Array where Element == AnyEndpointParameter {
    func exportParameters<I: InterfaceExporter>(on exporter: I) -> [I.ParameterExportOutput] {
        self.map { parameter -> I.ParameterExportOutput in
            parameter.exportParameter(on: exporter)
        }
    }
}

class ParameterBuilder: RequestInjectableVisitor {
    let requestInjectables: [String: RequestInjectable]
    var currentLabel: String?

    var parameters: [AnyEndpointParameter] = []

    init<C: Component>(from component: C) {
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

        var trimmedLabel = label
        if trimmedLabel.first == "_" {
            trimmedLabel.removeFirst()
        }

        let endpointParameter: AnyEndpointParameter
        if let optionalParameter = parameter as? EncodeOptionalEndpointParameter {
            endpointParameter = optionalParameter.createParameterWithWrappedType(
                    name: parameter.name ?? trimmedLabel,
                    label: label
            )
        } else {
            var `default`: Element?
            if let value = parameter.defaultValue {
                `default` = value
            }

            endpointParameter = EndpointParameter<Element>(
                    id: parameter.id,
                    name: parameter.name ?? trimmedLabel,
                    label: label,
                    necessity: .required,
                    options: parameter.options,
                    defaultValue: `default`
            )
        }

        parameters.append(endpointParameter)
    }
}

protocol EncodeOptionalEndpointParameter {
    func createParameterWithWrappedType(
            name: String,
            label: String
    ) -> AnyEndpointParameter
}

// MARK: Parameter Model
extension Parameter: EncodeOptionalEndpointParameter where Element: ApodiniOptional, Element.Member: Codable {
    func createParameterWithWrappedType(
            name: String,
            label: String
    ) -> AnyEndpointParameter {
        var `default`: Element.Member?
        if let value = self.defaultValue {
            `default` = value.optionalInstance
        }

        return EndpointParameter<Element.Member>(
                id: self.id,
                name: name,
                label: label,
                necessity: .optional,
                options: self.options,
                defaultValue: `default`
        )
    }
}

protocol LosslessStringConvertibleEndpointParameter {
    /// Initializes a type `T` for which you know that it conforms to `LosslessStringConvertible`.
    ///
    /// - Parameters:
    ///   - description: The Lossless string description for the `type`
    ///   - type: The type used as initializer
    /// - Returns: The result of `LosslessStringConvertible.init(...)`. Nil if the Type couldn't be instantiated for the given `String`
    func initFromDescription<T>(description: String, type: T.Type) -> T?
}

extension EndpointParameter: LosslessStringConvertibleEndpointParameter where Type: LosslessStringConvertible {
    func initFromDescription<T>(description: String, type: T.Type) -> T? {
        guard T.self is Type.Type else {
            fatalError("""
                       EndpointParameter.initFromDescription: Tried initializing from LosslessStringConvertible
                       for a T which didn't match the EndpointParameter Type
                       """)
        }

        // swiftlint:disable:next explicit_init
        let instance = Type.init(description)
        // swiftlint:disable:next force_cast
        return instance as! T?
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
