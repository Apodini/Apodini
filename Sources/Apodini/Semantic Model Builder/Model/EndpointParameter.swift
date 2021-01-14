//
//  EndpointParameter.swift
//  
//
//  Created by Lorena Schlesinger on 06.12.20.
//

import Foundation

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
protocol AnyEndpointParameter: CustomStringConvertible {
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
    /// Use the `nilIsValidValue` property to check if the original parameter definition used an `Optional` type.
    var propertyType: Codable.Type { get }
    /// See documentation of `propertyType`
    var nilIsValidValue: Bool { get }
    /// Holds the options as defined by the user.
    var options: PropertyOptionSet<ParameterOptionNameSpace> { get }
    /// Defines the `Necessity` of the parameter.
    var necessity: Necessity { get }
    /// Defines the `EndpointParameterType` of the parameter.
    var parameterType: ParameterType { get }
    /// Specifies the default value for the parameter. Nil if the parameter doesn't have a default value.
    var typeErasuredDefaultValue: Any? { get }

    /// See `CustomStringConvertible`
    var description: String { get }

    func accept<Visitor: EndpointParameterVisitor>(_ visitor: Visitor) -> Visitor.Output
    func accept<Visitor: EndpointParameterThrowingVisitor>(_ visitor: Visitor) throws -> Visitor.Output

    /// This method is used to call `InterfaceExporter.retrieveParameter(...)` on
    /// the given `InterfaceExporter`
    ///
    /// - Parameter exporter: The `InterfaceExporter`.
    /// - Returns: Returns what `InterfaceExporter.retrieveParameter(...)` returns.
    func exportParameter<I: BaseInterfaceExporter>(on exporter: I) -> I.ParameterExportOutput

    func derivePathParameterModel() -> EndpointPath
}

/// Models a `Parameter`. See `AnyEndpointParameter` for detailed documentation.
///
/// Be aware that for optional `Parameter` the generic `Type` holds the wrapped type of the `Optional`.
/// For the following declaration
/// ```
/// @Parameter var name: String?
/// ```
/// the generic holds `String.Type` and not `Optional<String>.self`.
/// Use the `nilIsValidValue` property to check if the original parameter definition used an `Optional` type.
struct EndpointParameter<Type: Codable>: AnyEndpointParameter {
    let id: UUID
    var pathId: String {
        if parameterType != .path {
            fatalError("Cannot access EndpointParameter.pathId when the parameter type isn't .path!")
        }
        return "\(id)"
    }
    let name: String
    let label: String
    let propertyType: Codable.Type
    let nilIsValidValue: Bool
    let options: PropertyOptionSet<ParameterOptionNameSpace>
    let necessity: Necessity
    let parameterType: ParameterType

    let defaultValue: Type?
    var typeErasuredDefaultValue: Any? {
        defaultValue
    }

    let description: String

    init(id: UUID,
         name: String,
         label: String,
         nilIsValidValue: Bool,
         necessity: Necessity,
         options: PropertyOptionSet<ParameterOptionNameSpace>,
         defaultValue: Type? = nil
    ) {
        self.id = id
        self.name = name
        self.label = label
        self.propertyType = Type.self
        self.nilIsValidValue = nilIsValidValue
        self.options = options
        self.necessity = necessity
        self.defaultValue = defaultValue

        // If somebody wants to make this more fancy, one could add options into the @Parameter initializer
        var description = "@Parameter var \(name): \(Type.self)"
        if nilIsValidValue {
            description += "?"
        }
        if let `default` = defaultValue {
            description += " = \(`default`)"
        }
        self.description = description

        let httpOption = options.option(for: PropertyOptionKey.http)
        switch httpOption {
        case .path:
            precondition(Type.self is LosslessStringConvertible.Type, "Invalid explicit option .path for '\(description)'. Option is only available for wrapped properties conforming to \(LosslessStringConvertible.self).")
            parameterType = .path
        case .query:
            precondition(Type.self is LosslessStringConvertible.Type, "Invalid explicit option .query for '\(description)'. Option is only available for wrapped properties conforming to \(LosslessStringConvertible.self).")
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

    func exportParameter<I: BaseInterfaceExporter>(on exporter: I) -> I.ParameterExportOutput {
        exporter.exportParameter(self)
    }
}

// MARK: Endpoint Parameter
extension Array where Element == AnyEndpointParameter {
    func exportParameters<I: BaseInterfaceExporter>(on exporter: I) -> [I.ParameterExportOutput] {
        self.map { parameter -> I.ParameterExportOutput in
            parameter.exportParameter(on: exporter)
        }
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

// MARK: LosslessStringConvertible Initializer
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
