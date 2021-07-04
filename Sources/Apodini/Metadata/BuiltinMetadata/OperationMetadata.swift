//
//  OperationMetadata.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

// MARK: Public API

/// Defines the Operation of a given endpoint
public enum Operation: String, CaseIterable, Hashable, CustomStringConvertible {
    /// The associated endpoint is used for a `create` operation
    case create
    /// The associated endpoint is used for a `read` operation
    case read
    /// The associated endpoint is used for a `update` operation
    case update
    /// The associated endpoint is used for a `delete` operation
    case delete

    public var description: String {
        rawValue
    }
}

public struct OperationContextKey: OptionalContextKey {
    public typealias Value = Operation
}

extension HandlerMetadataNamespace {
    /// Name Definition for the `OperationHandlerMetadata`
    public typealias Operation = OperationHandlerMetadata
}

/// The `OperationHandlerMetadata` can be used to explicitly specify the `Operation` for a given `Handler`.
/// The Metadata is available under the `HandlerMetadataNamespace.Operation` name and can be used like the following:
/// ```swift
/// struct ExampleHandler: Handler {
///     // ...
///     var metadata: Metadata {
///         Operation(.read)
///     }
/// }
/// ```
public struct OperationHandlerMetadata: HandlerMetadataDefinition {
    public typealias Key = OperationContextKey
    public let value: Operation

    /// Creates a new Operation Metadata.
    /// - Parameter operation: The `Operation` assigned to the `Handler`.
    public init(_ operation: Operation) {
        self.value = operation
    }
}

extension Handler {
    /// A `Handler.operation(...)` modifier can be used to explicitly specify the `Operation` Metadata for the given `Handler`
    /// - Parameter operation: The `Operation` that is used to for the handler
    /// - Returns: The modified `Handler` with a specified `Operation`
    public func operation(_ operation: Apodini.Operation) -> HandlerMetadataModifier<Self> {
        HandlerMetadataModifier(modifies: self, with: OperationHandlerMetadata(operation))
    }
}
