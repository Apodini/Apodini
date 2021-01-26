//
// Created by Andreas Bauer on 22.01.21.
//

import Foundation

/// A HandledRequest describes the outcome of a `ConnectionContext.handle(...)`.
public struct HandledRequest: Encodable {
    private let endpoint: AnyEndpoint

    let response: AnyEncodable
    private let parameters: [UUID: Any]

    init(for endpoint: AnyEndpoint, response: AnyEncodable, parameters: [UUID: Any]) {
        self.endpoint = endpoint
        self.response = response
        self.parameters = parameters
    }

    public func encode(to encoder: Encoder) throws {
        try response.encode(to: encoder)
    }

    /// Used to apply a `RelationshipFormatter` to Relationships for a given `Operation`
    /// with the context of this `HandledRequest` (path parameter values and property values of the response).
    /// If nil is supplied for the `Operation`, the formatter is called for any `Operation`.
    ///
    /// - Parameters:
    ///   - initialValue: The initial value the `RelationshipFormatter` should reduce into.
    ///   - formatter: The actual instance of the `RelationshipFormatter`.
    ///   - operation: The `Operation` for which to retrieve all `RelationshipDestination` from the given `Endpoint`.
    /// - Returns: The formatted result.
    public func formatRelationships<Formatter: RelationshipFormatter>(
        into initialValue: Formatter.Result,
        with formatter: Formatter,
        for operation: Operation? = nil
    ) -> Formatter.Result {
        let context = ResolveContext(content: response.any(), parameters: parameters)

        let destinations: Set<RelationshipDestination>
        if let operation = operation {
            destinations = endpoint.relationship(for: operation)
        } else {
            destinations = endpoint.relationships()
        }

        return destinations.formatRelationships(into: initialValue, with: formatter, context: context)
    }

    /// Used to apply a `RelationshipFormatter` to the self relationships of the `Endpoint`
    /// with the context of this `HandledRequest` (path parameter values and property values of the response).
    /// If nil is supplied for the `Operation`, the formatter is called for any `Operation`.
    /// If there is no self relationship for a specified `Operation`, this call simply returns the initial value.
    ///
    /// - Parameters:
    ///   - initialValue: The initial value the `RelationshipFormatter` should reduce into.
    ///   - formatter: The actual instance of the `RelationshipFormatter`.
    ///   - operation: The `Operation` for which to retrieve all self `RelationshipDestination` from the given `Endpoint`.
    /// - Returns: The formatted result
    func formatSelfRelationships<Formatter: RelationshipFormatter>(
        into initialValue: Formatter.Result,
        with formatter: Formatter,
        for operation: Operation? = nil
    ) -> Formatter.Result {
        let context = ResolveContext(content: response.any(), parameters: parameters)

        var result = initialValue

        if let specifiedOperation = operation {
            endpoint.selfRelationship(for: specifiedOperation)?.formatRelationship(with: formatter, result: &result, context: context)
        } else {
            result = endpoint.selfRelationships().formatRelationships(into: result, with: formatter, context: context)
        }

        return result
    }

    /// Used to apply a `RelationshipFormatter` to THE self relationships of the `Endpoint`
    /// with the context of this `HandledRequest` (path parameter values and property values of the response).
    /// It is different to `formatSelfRelationships(into:with:for:)` that it used the one and only self
    /// `RelationshipDestination` of the Endpoint (Using the Operation of the Endpoint).
    ///
    /// - Parameters:
    ///   - initialValue: The initial value the `RelationshipFormatter` should reduce into.
    ///   - formatter: The actual instance of the `RelationshipFormatter`.
    func formatSelfRelationship<Formatter: RelationshipFormatter>(
        into initialValue: inout Formatter.Result,
        with formatter: Formatter
    ) {
        let context = ResolveContext(content: response.any(), parameters: parameters)
        endpoint.selfRelationship.formatRelationship(with: formatter, result: &initialValue, context: context)
    }
}

extension HandledRequest {
    // Having this extension mimicking `AnyEncodable` makes it transparent
    // to exporters who are only interested in the raw response value
    // and ignore stuff like Relationships.

    /// Returns the typed version of the stored response property.
    /// - Parameter type: The type to cast to.
    /// - Returns: Returns the casted type, nil if type didn't fit
    public func typed<T: Encodable>(_ type: T.Type = T.self) -> T? {
        response.typed(type)
    }
}
