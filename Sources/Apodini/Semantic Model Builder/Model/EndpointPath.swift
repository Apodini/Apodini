//
// Created by Andi on 03.01.21.
//

import Foundation

enum EndpointPath: CustomStringConvertible, CustomDebugStringConvertible {
    case root
    case string(_ path: String)
    case parameter(_ parameter: AnyEndpointPathParameter)

    var description: String {
        switch self {
        case .root:
            return ""
        case .string(let path):
            return path
        case .parameter(let parameter):
            return parameter.description
        }
    }

    var debugDescription: String {
        switch self {
        case .root:
            return "<root>"
        default:
            return description
        }
    }

    func scoped(on endpoint: AnyEndpoint) -> EndpointPath {
        switch self {
        case let .parameter(parameter):
            var parameter = parameter
            parameter.scoped(on: endpoint)
            return .parameter(parameter)
        default:
            return self
        }
    }
}

extension EndpointPath: Equatable {
    static func == (lhs: EndpointPath, rhs: EndpointPath) -> Bool {
        switch (lhs, rhs) {
        case (.root, .root):
            return true
        case let (.string(lhsPath), .string(rhsPath)):
            return lhsPath == rhsPath
        case let (.parameter(lhsParameter), .parameter(rhsParameter)):
            return lhsParameter.id == rhsParameter.id
        default:
            return false
        }
    }
}

extension EndpointPath: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .root:
            // we just use the seed of the hasher as the hash value
            break
        case let .string(path):
            path.hash(into: &hasher)
        case let .parameter(parameter):
            parameter.description.hash(into: &hasher)
        }
    }
}

/// Describes a type erasured `EndpointPathParameter`
protocol AnyEndpointPathParameter: CustomStringConvertible {
    /// The id uniquely identifying the parameter
    var id: UUID { get }
    /// The string representation of the `id` as it is the only stable and unique information
    /// about the path parameter.
    var pathId: String { get }
    /// A string description of the PathParameter.
    /// The `id` will be prefixed with a ":" to signal a path parameter
    var description: String { get }
    /// Use this property to check if the original parameter definition used an `Optional` type.
    var nilIsValidValue: Bool { get }

    /// Internal method to provide `PathBuilder` functionality
    func accept<Builder: PathBuilder>(_ builder: inout Builder)

    /// Internal method to create a scoped version of the PathParameter.
    /// Some information about a PathParameter is only existent in the scope
    /// of a specific Endpoint, on which the PathParameter is used.
    ///
    /// The following properties are only available on scoped `EndpointPathParameter`s:
    /// - `name`
    /// - `scopedEndpointHasDefinedParameter`
    ///
    /// - Parameter endpoint: The scope to use for the Parameter
    mutating func scoped(on endpoint: AnyEndpoint)

    /// This property returns if the scoped Endpoint has a proper `Parameter` definition in the Handler.
    /// If such definition is not present we can't provide a user friendly name, and thus `name` will default to `pathId`.
    var scopedEndpointHasDefinedParameter: Bool { get }

    /// The name for the parameter. As PathParameter don't allow for custom name definitions
    /// this will always be the property name as defined in the `Handler`.
    var name: String { get }
}

/// Models a `Parameter` created from a `PathParameter`. See `AnyEndpointPathParameter` for detailed documentation.
///
/// Be aware that for optional `Parameter` the generic `Type` holds the wrapped type of the `Optional`.
/// For the following declaration
/// ```
/// @Parameter var name: String?
/// ```
/// the generic holds `String.Type` and not `Optional<String>.self`.
/// Use the `nilIsValidValue` property to check if the original parameter definition used an `Optional` type.
struct EndpointPathParameter<Type: Codable>: AnyEndpointPathParameter {
    let id: UUID
    var pathId: String {
        id.uuidString
    }
    var description: String {
        ":\(id)"
    }
    var nilIsValidValue: Bool

    var scopedEndpointHasDefinedParameter: Bool {
        guard let value = storedScopedEndpointHasDefinedParameter else {
            fatalError("Tried accessing 'scopedEndpointHasDefinedParameter' property without a valid Endpoint scope!")
        }
        return value
    }
    private var storedScopedEndpointHasDefinedParameter: Bool? // swiftlint:disable:this discouraged_optional_boolean

    var name: String {
        guard let name = storedName else {
            fatalError("Tried accessing 'name' property without a valid Endpoint scope!")
        }
        return name
    }
    private var storedName: String?

    init(id: UUID, nilIsValidValue: Bool) {
        self.id = id
        self.nilIsValidValue = nilIsValidValue
    }

    mutating func scoped(on endpoint: AnyEndpoint) {
        if let parameter = endpoint.findParameter(for: id) {
            storedName = parameter.name
            storedScopedEndpointHasDefinedParameter = true
        } else {
            storedName = pathId
            storedScopedEndpointHasDefinedParameter = false
        }
    }

    func accept<Builder: PathBuilder>(_ builder: inout Builder) {
        builder.append(self)
    }
}


protocol PathBuilder {
    /// Optional method which is called for `.root` path elements
    mutating func root()

    /// Called to append a `String` path element
    mutating func append(_ string: String)
    /// Called to append a `EndpointPathParameter` element
    mutating func append<Type>(_ parameter: EndpointPathParameter<Type>)
}

extension PathBuilder {
    mutating func root() {}
}

// MARK: PathBuilder
extension EndpointPath {
    func accept<Builder: PathBuilder>(_ builder: inout Builder) {
        switch self {
        case .root:
            builder.root()
        case let .string(string):
            builder.append(string)
        case let .parameter(parameter):
            parameter.accept(&builder)
        }
    }
}

extension Array where Element == EndpointPath {
    func acceptAll<Builder: PathBuilder>(_ builder: inout Builder) {
        for path in self {
            path.accept(&builder)
        }
    }
}

extension Array where Element == EndpointPath {
    func scoped(on endpoint: AnyEndpoint) -> [Element] {
        map { path in
            path.scoped(on: endpoint)
        }
    }
}


extension Array where Element == EndpointPath {
    func asPathString(delimiter: String = "/") -> String {
        var stringBuilder = PathStringBuilder(delimiter: delimiter)
        self.acceptAll(&stringBuilder)
        return stringBuilder.build()
    }
}

private struct PathStringBuilder: PathBuilder {
    private let delimiter: String
    private var paths: [String] = []

    init(delimiter: String = "/") {
        self.delimiter = delimiter
    }

    mutating func root() {
        // prepending `paths` with and empty string, will result in paths=["", "what", "ever", "path"]
        // and properly encodes root path: build() = "/what/ever/path"
        paths.append("")
    }

    mutating func append(_ string: String) {
        paths.append(string)
    }

    mutating func append<Type>(_ parameter: EndpointPathParameter<Type>) {
        paths.append(parameter.description)
    }

    func build() -> String {
        paths.joined(separator: delimiter)
    }
}
