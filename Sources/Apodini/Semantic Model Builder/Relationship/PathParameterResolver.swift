//
// Created by Andreas Bauer on 19.01.21.
//

import Foundation
import ApodiniUtils
@_implementationOnly import AssociatedTypeRequirementsVisitor

typealias MatchedResolvers = [UUID: AnyPathParameterResolver]

/// A `AnyParameterResolver` can be used to resolve a `PathParameter`
/// of the destination of a `EndpointRelationship`.
protocol AnyPathParameterResolver: CustomStringConvertible {
    /// Checks whether this resolvers is able to resolve the given `AnyEndpointPathParameter`
    func resolves(parameter: AnyEndpointPathParameter) -> Bool

    /// Resolves the value for a path parameter from the given `ResolveContext`.
    ///
    /// - Parameter context: The `ResolveContext`.
    /// - Returns: The resolved value or nil if it didn't find a value.
    func resolve(context: ResolveContext) -> Any?
}

/// Context struct to handle resolve step.
public struct ResolveContext {
    /// Create a new ``ResolveContext``
    ///
    /// - Parameters:
    ///     - `content`:  the response's content
    ///     - `parameters`: a closure providing access to the request's values for each ``Parameter`` identified by its internal id
    public init(content: Any, parameters: @escaping (UUID) -> Any?) {
        self.content = content
        self.parameters = parameters
    }
    
    /// The content of the response.
    public let content: Any
    /// The parameter values of the current request
    public let parameters: (UUID) -> Any?
}

/// A resolver for a path parameter using the value of a property.
/// Generics `Element` is the type where the property is stored and `Type` the
/// type of the property where the value is stored.
struct PathParameterPropertyResolver<Element, Destination: Identifiable>: AnyPathParameterResolver {
    var description: String {
        "PropertyResolver(of: \(identifyingType.type).\(identifyingType.idType), at: \(keyPath))"
    }

    let identifyingType: IdentifyingType
    let keyPath: PartialKeyPath<Element>

    init(destination type: Destination.Type = Destination.self, at keyPath: PartialKeyPath<Element>) {
        self.identifyingType = IdentifyingType(identifying: type)
        self.keyPath = keyPath
    }

    func resolves(parameter: AnyEndpointPathParameter) -> Bool {
        // This line basically creates the restriction that we require the `identifyingType`
        // to be supplied with the `@PathParameter` definition.
        // Additionally, `parameter.identifyingType` holds the `IdentifyingType` as defined
        // in the `PathParameter`, requiring the `LosslessStringConvertible` and non Optional restriction.
        identifyingType == parameter.identifyingType
    }

    func resolve(context: ResolveContext) -> Any? {
        guard let content = context.content as? Element else {
            fatalError("Tried resolving with \(self) but couldn't cast the given response \(context.content) to \(Element.self)!")
        }

        let value = content[keyPath: keyPath]
        let valueType = type(of: value)

        if isOptional(valueType) {
            precondition(valueType == Destination.ID?.self,
                         "The retrieved value \(value) of type \(valueType) didn't match expected optional type of \(Destination.ID.self)")
        } else {
            precondition(valueType == Destination.ID.self,
                         "The retrieved value \(value) of type \(valueType) didn't match expected type \(Destination.ID.self)")
        }
        
        if isNil(value) {
            // if the property is of type Optional and the value is Optional.none
            // we return nil to signify the non existence for this value.
            return nil
        }

        return content[keyPath: keyPath]
    }
}

struct PathParameterResolver: AnyPathParameterResolver {
    var description: String {
        "ParameterResolver(of: \(parameterId))"
    }

    let parameterId: UUID

    func resolves(parameter: AnyEndpointPathParameter) -> Bool {
        parameterId == parameter.id
    }

    func resolve(context: ResolveContext) -> Any? {
        context.parameters(parameterId)
    }
}


extension ParsedTypeIndexEntryCapture {
    func asSource() -> RelationshipSourceCandidate {
        var resolvers = pathParameters.resolvers()

        // if the return type conforms to Identifiable we need
        // to create a potential resolver for the `id` property (as required by `Identifiable`)
        let visitor = IdentifiableIdPropertyResolverVisitor()
        if let propertyResolver = visitor(type) {
            resolvers.append(propertyResolver)
        }

        return RelationshipSourceCandidate(destinationType: type, reference: reference, resolvers: resolvers)
    }
}

extension Array where Element == AnyEndpointPathParameter {
    func resolvers() -> [AnyPathParameterResolver] {
        map { parameter in
            PathParameterResolver(parameterId: parameter.id)
        }
    }
}

extension Array where Element == AnyPathParameterResolver {
    /// This method checks if the given array of `AnyPathParameterResolver` is able to resolve any
    /// path parameters located in the path of the provided `EndpointReference`.
    /// - Parameters:
    ///   - reference: The `EndpointReference` to check resolvability for.
    ///   - pathParameters: The array where unresolved PathParameters are stored in.
    /// - Returns: Returns the list of `AnyPathParameterResolver` which weren't used for resolving steps.
    func resolvability(of path: [EndpointPath], unresolved pathParameters: inout [AnyEndpointPathParameter]) -> [AnyPathParameterResolver] {
        var unusedResolvers: [AnyPathParameterResolver] = self

        for parameter in path.listPathParameters() {
            if let index = unusedResolvers.firstIndex(where: { $0.resolves(parameter: parameter) }) {
                unusedResolvers.remove(at: index)
            } else {
                pathParameters.append(parameter)
            }
        }

        return unusedResolvers
    }
}

struct IdentifiableIdPropertyResolverVisitor: IdentifiableTypeVisitor {
    func callAsFunction<T: Identifiable>(_ value: T.Type) -> AnyPathParameterResolver {
        PathParameterPropertyResolver(destination: T.self, at: \T.id)
    }
}
