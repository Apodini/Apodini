//
//  EndpointParameter.swift
//  
//
//  Created by Lorena Schlesinger on 06.12.20.
//

import Foundation

/// `@Parameter` categorization needed for certain interface exporters, e.g., HTTP-based.
enum EndpointParameterKind {
    case lightweight
    case content
    case path
}

/// Defines the necessity of a `EndpointParameter`
enum EndpointParameterNecessity {
    case required
    case optional
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
    /// The `Necessity` of the parameter.
    var necessity: EndpointParameterNecessity { get }
    /// The `Kind` of the parameter.
    var kind: EndpointParameterKind { get }
    /// Specifies the default value for the parameter. Nil if the parameter doesn't have a default value.
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
/// Use the `nilIsValidValue` property to check if the original parameter definition used an `Optional` type.
struct EndpointParameter<Type: Codable>: AnyEndpointParameter {
    let id: UUID
    var pathId: String {
        if kind != .path {
            fatalError("Cannot access EndpointParameter.pathId when the parameter type isn't .path!")
        }
        return ":\(id)"
    }
    let name: String
    let label: String
    let propertyType: Codable.Type
    let nilIsValidValue: Bool
    let options: PropertyOptionSet<ParameterOptionNameSpace>
    let necessity: EndpointParameterNecessity
    let kind: EndpointParameterKind

    let defaultValue: Type?
    var typeErasuredDefaultValue: Any? {
        defaultValue
    }

    let description: String

    init(id: UUID,
         name: String,
         label: String,
         nilIsValidValue: Bool,
         necessity: EndpointParameterNecessity,
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
            kind = .path
        case .query:
            precondition(Type.self is LosslessStringConvertible.Type, "Invalid explicit option .query for '\(description)'. Option is only available for wrapped properties conforming to \(LosslessStringConvertible.self).")
            kind = .lightweight
        case .body:
            kind = .content
        default:
            kind = Type.self is LosslessStringConvertible.Type ? .lightweight : .content
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
