//
//  CommunicationalPatternMetadata.swift
//  
//
//  Created by Max Obermeier on 30.06.21.
//

import Foundation

public enum CommunicationalPattern {
    /// **One** client message followed by **one** service message
    case requestResponse
    /// **Any amount** of client messages followed by **one** service message
    case clientSideStream
    /// **One** client message followed by **any amount** of service messages
    case serviceSideStream
    /// **Any amount** of client messages and **any amount** of service messages in an **undefined order**
    case bidirectionalStream
}


public struct CommunicationalPatternContextKey: OptionalContextKey {
    public typealias Value = CommunicationalPattern
}

extension HandlerMetadataNamespace {
    /// Name Definition for the `ComponentDescriptionMetadata`
    public typealias Pattern = ComponentDescriptionMetadata
}

/// The ``CommunicationalPatternMetadata`` can be used to explicitly declare a ``Handler``'s
/// ``CommunicationalPattern``.
///
/// The framework can automatically detect ``CommunicationalPattern/requestResponse`` if the
/// ``Handler/handle()-94skg``'s return type is no ``Response``. If that is not the case and you don't
/// explicitly specify the ``HandlerMetadataNamespace/Pattern``, the ``Handler`` is assumed to use
/// ``CommunicationalPattern/bidirectionalStream``.
///
/// - Note: This modifier has no influence on how the associated ``Handler`` is handled by the framework.
/// Instead, it merely helps ``InterfaceExporter``s to find an appropriate representation in their respective
/// middleware.
///
/// The Metadata is available under the ``HandlerMetadataNamespace/Pattern`` name and can be used like the following:
/// ```swift
/// struct ExampleHandler: Handler {
///     // ...
///     var metadata: Metadata {
///         Pattern(.clientSideStream)
///     }
/// }
/// ```
public struct CommunicationalPatternMetadata: HandlerMetadataDefinition {
    public typealias Key = CommunicationalPatternContextKey
    public let value: CommunicationalPattern

    /// Creates a new ``CommunicationalPattern`` Metadata
    /// - Parameter pattern: The pattern for the ``Handler``.
    public init(_ pattern: CommunicationalPattern) {
        self.value = pattern
    }
}

extension Handler {
    /// A `pattern` Modifier can be used to specify the ``CommunicationalPatternMetadata`` via a ``HandlerModifier``.
    /// - Parameter value: The communicational pattern of the associated ``Handler``.
    /// - Returns: The modified `Handler` with the `CommunicationalPatternMetadata` added.
    public func pattern(_ value: CommunicationalPattern) -> HandlerMetadataModifier<Self> {
        HandlerMetadataModifier(modifies: self, with: CommunicationalPatternMetadata(value))
    }
}
