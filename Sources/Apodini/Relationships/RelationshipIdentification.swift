//
// Created by Andreas Bauer on 21.01.21.
//

/// A type erasured version of an `RelationshipIdentification`.
public struct AnyRelationshipIdentification {
    let resolver: AnyPathParameterResolver

    init<From, To: Identifiable>(from identification: RelationshipIdentification<From, To>) {
        resolver = identification.resolver()
    }
}

extension TypedContentMetadataNamespace {
    /// Shorthand for using a pretyped `RelationshipIdentification`.
    public typealias Identifying<To: Identifiable> = RelationshipIdentification<Self, To> where To.ID: LosslessStringConvertible
}

/// A `RelationshipIdentification` provides additional information to resolve path parameter
/// values to the destination of a relationship, e.g. defined by `RelationshipInheritance`, `RelationshipReference`
/// or `RelationshipSource`.
/// The path parameter which should be resolved must be annotated
/// with a identifying type using `PathParameter.init(identifying:)`.
public struct RelationshipIdentification<From, To: Identifiable> where To.ID: LosslessStringConvertible {
    let type: To.Type
    let keyPath: PartialKeyPath<From>

    /// Initializes a new `RelationshipIdentification`.
    ///
    /// The Metadata is available under the name `Identifying` like the following:
    /// ```swift
    /// Identifying<SomeType>(identifiedBy: \.someId)
    /// ```
    ///
    /// - Parameters:
    ///   - type: The identifying type of the `PathParameter` to provide a resolved value.
    ///   - keyPath: KeyPath to the property holding a value for the path parameter.
    public init(_ type: To.Type = To.self, identifiedBy keyPath: KeyPath<From, To.ID>) {
        self.type = type
        self.keyPath = keyPath
    }

    /// Initializes a new `RelationshipIdentification`.
    ///
    /// The Metadata is available under the name `Identifying` like the following:
    /// ```swift
    /// // \.someId is of type Optional, thus the Parameter is only resolved when value is non nil.
    /// Identifying<SomeType>(identifiedBy: \.someId)
    /// ```
    ///
    /// - Parameters:
    ///   - type: The identifying type of the `PathParameter` to provide a resolved value.
    ///   - keyPath: KeyPath to the property holding a value for the path parameter.
    public init(_ type: To.Type = To.self, identifiedBy keyPath: KeyPath<From, To.ID?>) {
        self.type = type
        self.keyPath = keyPath
    }

    func resolver() -> AnyPathParameterResolver {
        PathParameterPropertyResolver(destination: type, at: keyPath)
    }
}
