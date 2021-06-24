//
// Created by Andreas Bauer on 03.01.21.
//

import Foundation

public enum EndpointPath: CustomStringConvertible, CustomDebugStringConvertible {
    case root
    case string(_ path: String)
    case parameter(_ parameter: AnyEndpointPathParameter)

    public var description: String {
        switch self {
        case .root:
            return ""
        case .string(let path):
            return path
        case .parameter(let parameter):
            return parameter.description
        }
    }

    public var debugDescription: String {
        if case .root = self {
            return "<root>"
        }
        return description
    }

    public func isString() -> Bool {
        if case .string = self {
            return true
        }
        return false
    }

    public func isParameter() -> Bool {
        if case .parameter = self {
            return true
        }
        return false
    }

    func scoped(on endpoint: ParameterCollection) -> EndpointPath {
        if case let .parameter(parameter) = self {
            var parameter = parameter.toInternal()
            parameter.scoped(on: endpoint)
            return .parameter(parameter)
        }

        return self
    }

    func unscoped() -> EndpointPath {
        if case let .parameter(parameter) = self {
            var parameter = parameter.toInternal()
            parameter.unscoped()
            return .parameter(parameter)
        }

        return self
    }
}

extension EndpointPath: Equatable {
    public static func == (lhs: EndpointPath, rhs: EndpointPath) -> Bool {
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
    public func hash(into hasher: inout Hasher) {
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

/// Describes a type erased `EndpointPathParameter`
public protocol AnyEndpointPathParameter: CustomStringConvertible {
    /// The id uniquely identifying the parameter
    var id: UUID { get }
    /// The string representation of the `id` as it is the only stable and unique information
    /// about the path parameter.
    var pathId: String { get }
    /// A string description of the PathParameter.
    /// The `id` will be prefixed with a ":" to signal a path parameter
    var description: String { get }
    /// Defines the property type of the `PathParameter` declaration in a statically accessible way.
    /// Use `PathBuilder` to access the `EndpointPathParameter` in a generic way.
    var propertyType: Codable.Type { get }
    /// Defines which data type the `EndpointPathParameter` is identifying,
    /// meaning the value of the path parameter uniquely identifies a instance of supplied data type.
    /// The property is an Optional as the user might not specify such a type with `@PathParameter`.
    var identifyingType: IdentifyingType? { get }

    /// This property returns if the scoped Endpoint has a proper `Parameter` definition in the Handler.
    /// If such definition is not present we can't provide a user friendly name, and thus `name` will default to `pathId`.
    var scopedEndpointHasDefinedParameter: Bool { get }

    /// The name for the parameter. As PathParameter don't allow for custom name definitions
    /// this will always be the property name as defined in the `Handler`.
    var name: String { get }

    /// The value for the given path parameter in the context of a specific request.
    /// Nil if the path parameter does not have a resolved value.
    /// See `resolved(value:)` for restrictions.
    var erasedResolvedValue: Any? { get }
}

extension AnyEndpointPathParameter {
    func toInternal() -> _AnyEndpointPathParameter {
        guard let parameter = self as? _AnyEndpointPathParameter else {
            fatalError("Encountered `AnyEndpointPathParameter` which doesn't conform to `_AnyEndpointPathParameter`: \(self)!")
        }
        return parameter
    }
}

protocol _AnyEndpointPathParameter: AnyEndpointPathParameter {
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
    mutating func scoped(on endpoint: ParameterCollection)

    /// Internal method to remove the scope of a PathParameter again.
    /// See `scoped(on:)` for more information on scoped PathParameters.
    mutating func unscoped()


    /// Internal method to create a resolved version of the PathParameter.
    /// Additionally to a scope, a EndpointPathParameter can also have a resolved state.
    /// A instance is only in that state within the context of a particular request.
    ///
    /// The following properties are only available on resolved `EndpointPathParameter`s:
    /// - `erasedResolvedValue`
    /// - `resolvedValue` (if you have access to the generic instance)
    ///
    /// - Parameter value: The resolved value for thus PathParameter.
    mutating func resolved(value: Any)
}

/// Models a `Parameter` created from a `PathParameter`. See `AnyEndpointPathParameter` for detailed documentation.
public struct EndpointPathParameter<Type: Codable>: _AnyEndpointPathParameter {
    public let id: UUID
    public var pathId: String {
        id.uuidString
    }
    public var description: String {
        ":\(id)"
    }

    public var propertyType: Codable.Type {
        Type.self
    }
    public var identifyingType: IdentifyingType?


    public var scopedEndpointHasDefinedParameter: Bool {
        guard let value = storedScopedEndpointHasDefinedParameter else {
            fatalError("Tried accessing 'scopedEndpointHasDefinedParameter' property without a valid Endpoint scope!")
        }
        return value
    }
    private var storedScopedEndpointHasDefinedParameter: Bool? // swiftlint:disable:this discouraged_optional_boolean

    public var name: String {
        guard let name = storedName else {
            fatalError("Tried accessing 'name' property without a valid Endpoint scope!")
        }
        return name
    }
    private var storedName: String?

    var resolvedValue: Type?
    public var erasedResolvedValue: Any? {
        resolvedValue
    }

    init(id: UUID, identifyingType: IdentifyingType? = nil) {
        self.id = id
        self.identifyingType = identifyingType
    }

    mutating func scoped(on endpoint: ParameterCollection) {
        precondition(storedScopedEndpointHasDefinedParameter == nil, "Cannot scope an already scoped EndpointPathParameter!")

        if let parameter = endpoint.findParameter(for: id) {
            storedName = parameter.name
            storedScopedEndpointHasDefinedParameter = true
        } else {
            storedName = pathId
            storedScopedEndpointHasDefinedParameter = false
        }
    }

    mutating func unscoped() {
        storedName = nil
        storedScopedEndpointHasDefinedParameter = nil
        resolvedValue = nil
    }

    mutating func resolved(value: Any) {
        guard let resolvedValue = value as? Type else {
            fatalError("The resolved value \(value) couldn't be casted to \(Type.self) for path parameter \(name)")
        }
        self.resolvedValue = resolvedValue
    }

    func accept<Builder: PathBuilder>(_ builder: inout Builder) {
        builder.append(self)
    }
}

// MARK: EndpointPath
extension Array where Element == EndpointPath {
    func scoped(on endpoint: ParameterCollection) -> [Element] {
        map { path in
            path.scoped(on: endpoint)
        }
    }

    func unscoped() -> [Element] {
        map { path in
            path.unscoped()
        }
    }
}

// MARK: EndpointPath
extension Array where Element == EndpointPath {
    mutating func assertRoot() {
        if isEmpty {
            fatalError("Tried asserting .root path on an empty array!")
        }
        let next = removeFirst()

        if case .root = next {
            return
        }

        fatalError("Tried asserting .root but encountered \(next)")
    }
}

// MARK: EndpointPath
extension Array where Element == EndpointPath {
    func listPathParameters() -> [AnyEndpointPathParameter] {
        reduce(into: []) { result, path in
            if case let .parameter(parameter) = path {
                result.append(parameter)
            }
        }
    }
}


/// This protocol describes a Path Builder.
/// Can be used to traverse any `[EndpointPath]`.
/// Can be applied using `[EndpointPath].build(...)`.
public protocol PathBuilder {
    /// Optional method which is called for `EndpointPath.root` path elements.
    /// Typically a such path elements are found at the beginning of any array
    /// representing a absolute path.
    mutating func root()

    /// Called to append a `EndpointPath.string(String)` path element.
    /// - Parameter string: The string hold by `.string` path.
    mutating func append(_ string: String)
    /// Called to append a `EndpointPath.parameter(EndpointPathParameter)` element.
    /// - Parameter parameter: The fully typed parameter of the `.parameter` path.
    mutating func append<Type>(_ parameter: EndpointPathParameter<Type>)
}

public extension PathBuilder {
    /// Called to append the `EndpointPath.root` path element.
    /// Typically a such path elements are found at the beginning of any array
    /// representing a absolute path.
    mutating func root() {}
}

public protocol PathBuilderWithResult: PathBuilder {
    associatedtype Result

    init()

    func result() -> Result
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
            parameter.toInternal().accept(&builder)
        }
    }
}

// MARK: PathBuilder
public extension Array where Element == EndpointPath {
    /// Applies and instantiated `PathBuilder` to the given `EndpointPath` array.
    /// - Parameter builder: The `PathBuilder` to be applied.
    func build<Builder: PathBuilder>(with builder: inout Builder) {
        for path in self {
            path.accept(&builder)
        }
    }

    /// Applies a `PathBuilderWithResult` to the given `EndpointPath` array.
    /// The path builder will be instantiated using the required initializer of the `PathBuilderResult` protocol.
    /// - Parameter type: The type of `PathBuilderWithResult` to be used for building.
    /// - Returns: Returns the result of `PathBuilderResult.result()` after building all paths.
    func build<Builder: PathBuilderWithResult>(with type: Builder.Type) -> Builder.Result {
        var builder: Builder = .init()
        for path in self {
            path.accept(&builder)
        }
        return builder.result()
    }
}

// MARK: PathBuilder
public extension Array where Element == EndpointPath {
    /// Turns the `EndpointPath` array into a string representation using the packaged `PathStringBuilder`.
    /// - Parameters:
    ///   - delimiter: Defines the delimiter between the string representation of the different `EndpointPath`s.
    ///   - parameterEncoding: Defines the `ParameterEncodingStyle` to be used for `EndpointPathParameter`.
    /// - Returns: The string representation for the `EndpointPath` array.
    func asPathString(delimiter: String = "/", parameterEncoding: ParameterEncodingStyle = .bracketedName) -> String {
        var builder = PathStringBuilder(delimiter: delimiter, parameterEncoding: parameterEncoding)
        build(with: &builder)
        return builder.result()
    }
}

/// Defines the how parameter should be encoded when using `[EndpointPath].asPathString(...)` (aka the `PathStringBuilder`)
public enum ParameterEncodingStyle {
    /// Uses a RFC 6670 style using.
    /// Example for parameter named `id`: `{id}`
    case bracketedName
    /// Uses the name of the parameter.
    /// The parameter might not be available, if the `Handler` of the scoped `Endpoint`
    /// didn't declare a `Parameter` property for the given path parameter.
    /// In this case the `EndpointPathParameter.id` is used.
    case name
    /// Uses the path parameter id.
    case id
    /// Uses the value of the parameter if available, otherwise the name of the parameter.
    case valueOrName
}

private struct PathStringBuilder: PathBuilder {
    private let delimiter: String
    private let parameterEncoding: ParameterEncodingStyle

    private var paths: [String] = []

    fileprivate init(delimiter: String = "/", parameterEncoding: ParameterEncodingStyle = .bracketedName) {
        self.delimiter = delimiter
        self.parameterEncoding = parameterEncoding
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
        switch parameterEncoding {
        case .bracketedName:
            paths.append("{\(parameter.name)}")
        case .name:
            paths.append(parameter.name)
        case .id:
            paths.append(parameter.description)
        case .valueOrName:
            if let value = parameter.resolvedValue {
                paths.append("\(value)")
            } else {
                paths.append("{\(parameter.name)}")
            }
        }
    }

    func result() -> String {
        paths.joined(separator: delimiter)
    }
}

class EndpointPathModule: KnowledgeSource {
    var absolutePath: [EndpointPath] {
        guard let value = _absolutePath else {
            fatalError("EndpointPathModule was used before the absolutePath was injected by the framework!")
        }
        return value
    }
    
    // swiftlint:disable:next discouraged_optional_collection
    private var _absolutePath: [EndpointPath]?
    
    required init<B>(_ blackboard: B) throws where B: Blackboard { }
    
    func inject(absolutePath: [EndpointPath]) {
        self._absolutePath = absolutePath
    }
}
