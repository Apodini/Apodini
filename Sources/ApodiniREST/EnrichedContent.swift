//
// Created by Andreas Bauer on 22.01.21.
//

import Foundation
import ApodiniUtils
import Apodini


/// A `EnrichedContent` describes the outcome of a `ConnectionContext.handle(...)`.
struct EnrichedContent: Encodable {
    private let endpoint: AnyRelationshipEndpoint

    let response: AnyEncodable
    private let parameters: (UUID) -> Any?

    init(for endpoint: AnyRelationshipEndpoint, response: AnyEncodable, parameters: @escaping (UUID) -> Any?) {
        self.endpoint = endpoint
        self.response = response
        self.parameters = parameters
    }

    func encode(to encoder: Encoder) throws {
        try response.encode(to: encoder)
    }

    /// Used to apply a `RelationshipFormatter` to Relationships for a given `Operation`
    /// with the context of this `EnrichedContent` (path parameter values and property values of the response).
    ///
    /// - Parameters:
    ///   - initialValue: The initial value the `RelationshipFormatter` should reduce into.
    ///   - formatter: The actual instance of the `RelationshipFormatter`.
    ///   - operation: The `Operation` for which to retrieve all `RelationshipDestination` from the given `Endpoint`.
    /// - Returns: The formatted result.
    func formatRelationships<Formatter: RelationshipFormatter>(
        into initialValue: Formatter.Result,
        with formatter: Formatter,
        for operation: Apodini.Operation
    ) -> Formatter.Result {
        let context = ResolveContext(content: response.wrappedValue, parameters: parameters)

        return endpoint
            .relationships(for: operation)
            .formatRelationships(into: initialValue, with: formatter, context: context)
    }

    /// Used to apply a `RelationshipFormatter` to all Relationships of the `Endpoint`
    /// with the context of this `EnrichedContent` (path parameter values and property values of the response).
    ///
    /// - Parameters:
    ///   - initialValue: The initial value the `RelationshipFormatter` should reduce into.
    ///   - formatter: The actual instance of the `RelationshipFormatter`.
    /// - Returns: The formatted result.
    func formatRelationships<Formatter: RelationshipFormatter>(
        into initialValue: Formatter.Result,
        with formatter: Formatter
    ) -> Formatter.Result {
        let context = ResolveContext(content: response.wrappedValue, parameters: parameters)

        return endpoint
            .relationships()
            .formatRelationships(into: initialValue, with: formatter, context: context)
    }

    /// Used to apply a `RelationshipFormatter` to all Relationships of the `Endpoint`
    /// with the context of this `EnrichedContent` (path parameter values and property values of the response).
    ///
    /// - Parameters:
    ///   - initialValue: The initial value the `RelationshipFormatter` should reduce into.
    ///   - formatter: The actual instance of the `RelationshipFormatter`.
    ///   - sortKeyPath: The relationships will be applied to the formatter in the given order.
    /// - Returns: The formatted result.
    func formatRelationships<Formatter: RelationshipFormatter, T: Comparable>(
        into initialValue: Formatter.Result,
        with formatter: Formatter,
        sortedBy sortKeyPath: KeyPath<Apodini.Operation, T>
    ) -> Formatter.Result {
        let context = ResolveContext(content: response.wrappedValue, parameters: parameters)

        var result = initialValue

        for operation in Operation.allCases.sorted(by: sortKeyPath) {
            result = endpoint
                .relationships(for: operation)
                .formatRelationships(into: result, with: formatter, context: context)
        }

        return result
    }

    /// Used to apply a `RelationshipFormatter` to the all self relationships of the `Endpoint`
    /// with the context of this `EnrichedContent` (path parameter values and property values of the response).
    ///
    /// - Parameters:
    ///   - initialValue: The initial value the `RelationshipFormatter` should reduce into.
    ///   - formatter: The actual instance of the `RelationshipFormatter`.
    /// - Returns: The formatted result.
    func formatSelfRelationships<Formatter: RelationshipFormatter>(
        into initialValue: Formatter.Result,
        with formatter: Formatter
    ) -> Formatter.Result {
        let context = ResolveContext(content: response.wrappedValue, parameters: parameters)

        return endpoint.selfRelationships().formatRelationships(into: initialValue, with: formatter, context: context)
    }

    /// Used to apply a `RelationshipFormatter` to THE self relationships of the `Endpoint`
    /// with the context of this `EnrichedContent` (path parameter values and property values of the response).
    /// It is different to `formatSelfRelationships(into:with:for:)` that it always uses the one and only self
    /// `RelationshipDestination` where operation equals to the operation of the `Endpoint`.
    /// Meaning the `RelationshipDestination` truly points to itself. This `RelationshipDestination`
    /// is guaranteed to exist.
    ///
    /// - Parameters:
    ///   - initialValue: The initial value the `RelationshipFormatter` should reduce into.
    ///   - formatter: The actual instance of the `RelationshipFormatter`.
    func formatSelfRelationship<Formatter: RelationshipFormatter>(
        into initialValue: inout Formatter.Result,
        with formatter: Formatter
    ) {
        let context = ResolveContext(content: response.wrappedValue, parameters: parameters)
        endpoint.selfRelationship.formatRelationship(with: formatter, result: &initialValue, context: context)
    }

    /// Used to apply a `RelationshipFormatter` to the self relationships of the `Endpoint` of a given `Operation`
    /// with the context of this `EnrichedContent` (path parameter values and property values of the response).
    ///
    /// - Parameters:
    ///   - initialValue: The initial value the `RelationshipFormatter` should reduce into.
    ///   - formatter: The actual instance of the `RelationshipFormatter`.
    ///   - operation: The `Operation` for which to retrieve the self `RelationshipDestination` from the given `Endpoint`.
    /// Returns: Returns whether a `RelationshipDestination` for the given `Operation` existed.
    func formatSelfRelationship<Formatter: RelationshipFormatter>(
        into initialValue: inout Formatter.Result,
        with formatter: Formatter,
        for operation: Apodini.Operation
    ) -> Bool {
        guard let relationship = endpoint.selfRelationship(for: operation) else {
            return false
        }
        let context = ResolveContext(content: response.wrappedValue, parameters: parameters)

        relationship.formatRelationship(with: formatter, result: &initialValue, context: context)
        return true
    }
}

extension EnrichedContent {
    // Having this extension mimicking `AnyEncodable` makes it transparent
    // to exporters who are only interested in the raw response value
    // and ignore stuff like Relationships.

    /// Returns the typed version of the stored response property.
    /// - Parameter type: The type to cast to.
    /// - Returns: Returns the casted type, nil if type didn't fit
    func typed<T: Encodable>(_ type: T.Type = T.self) -> T? {
        response.typed(type)
    }
}
