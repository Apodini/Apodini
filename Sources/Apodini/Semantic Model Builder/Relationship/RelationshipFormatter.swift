//
// Created by Andreas Bauer on 22.01.21.
//

/// This protocol can be used to format a set of RelationshipDestinations
public protocol RelationshipFormatter {
    /// Describes the output of the formatting process (e.g. a dictionary listing all relationships)
    associatedtype Result
    /// Defines the Format for a single `RelationshipDestination` (e.g. a String of the destinationPath)
    associatedtype RelationshipRepresentation

    /// This method is called to format a specific `RelationshipDestination`
    /// - Parameter destination: The `RelationshipDestination` which is to be formatted.
    /// - Returns: The formatted relationship or nil if the specific relationship should not be included in the `Result`.
    func format(destination: RelationshipDestination) -> RelationshipRepresentation?

    /// Adds a specific already formatted `RelationshipRepresentation` the the `Result`
    /// - Parameters:
    ///   - representation: The result of the `format(...)` call.
    ///   - of: The `RelationshipDestination` `format(...)` was called for.
    ///   - into: The `Result` which the `representation` should be written to.
    func reduce(representation: RelationshipRepresentation, of: RelationshipDestination, into: inout Result)
}


// MARK: RelationshipFormatter
extension RelationshipDestination {
    /// Used to apply a `RelationshipFormatter` to a single `RelationshipDestinations`.
    /// - Parameters:
    ///   - formatter: The actual instance of the `RelationshipFormatter`.
    ///   - result: The `Formatter.Result` to write into.
    public func formatRelationship<Formatter: RelationshipFormatter>(
        with formatter: Formatter,
        result: inout Formatter.Result
    ) {
        formatRelationship(with: formatter, result: &result, context: nil)
    }

    /// Used to apply a `RelationshipFormatter` to a single `RelationshipDestinations`.
    /// - Parameters:
    ///   - formatter: The actual instance of the `RelationshipFormatter`.
    ///   - result: The `Formatter.Result` to write into.
    ///   - context: Optional `ResolveContext`. If present this can be used to resolve path parameters.
    public func formatRelationship<Formatter: RelationshipFormatter>(
        with formatter: Formatter,
        result: inout Formatter.Result,
        context: ResolveContext?
    ) {
        var relationship = self
        if let context = context {
            relationship.resolveParameters(context: context)
        }

        if let representation = formatter.format(destination: relationship) {
            formatter.reduce(representation: representation, of: relationship, into: &result)
        }
    }
}

// MARK: RelationshipFormatter
extension Set where Element == RelationshipDestination {
    /// Used to apply a `RelationshipFormatter` to all `RelationshipDestinations`.
    /// - Parameters:
    ///   - initialValue: The initial value the `RelationshipFormatter` should reduce into.
    ///   - formatter: The actual instance of the `RelationshipFormatter`.
    ///   - includeSelf: If true the special self relationship will also be formatted (as last one).
    /// - Returns: The fully formatted `Formatter.Result`.
    public func formatRelationships<Formatter: RelationshipFormatter>(
        into initialValue: Formatter.Result,
        with formatter: Formatter
    ) -> Formatter.Result {
        formatRelationships(into: initialValue, with: formatter, context: nil)
    }

    /// Used to apply a `RelationshipFormatter` to all `RelationshipDestinations`.
    /// - Parameters:
    ///   - initialValue: The initial value the `RelationshipFormatter` should reduce into.
    ///   - formatter: The actual instance of the `RelationshipFormatter`.
    ///   - includeSelf: If true the special self relationship will also be formatted (as last one).
    ///   - context: Optional `ResolveContext`. If present this can be used to resolve path parameters.
    /// - Returns: The fully formatted `Formatter.Result`.
    public func formatRelationships<Formatter: RelationshipFormatter>(
        into initialValue: Formatter.Result,
        with formatter: Formatter,
        context: ResolveContext?
    ) -> Formatter.Result {
        var result = initialValue

        for relationship in self {
            relationship.formatRelationship(with: formatter, result: &result, context: context)
        }

        return result
    }
}
