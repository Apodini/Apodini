//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation

/// A type describing the kind of communication that a ``Handler`` is designed for.
///
/// The pattern in a communication is defined by the quantity and order of messages
/// that are sent from client to server and from server to client.
public enum CommunicationPattern: String, CaseIterable {
    /// **One** client message followed by **one** service message
    case requestResponse
    /// **Any amount** of client messages followed by **one** service message
    case clientSideStream
    /// **One** client message followed by **any amount** of service messages
    case serviceSideStream
    /// **Any amount** of client messages and **any amount** of service messages in an **undefined order**
    case bidirectionalStream
    
    /// Whether the communication pattern is stream-based
    public var isStream: Bool {
        switch self {
        case .requestResponse:
            return false
        case .clientSideStream, .serviceSideStream, .bidirectionalStream:
            return true
        }
    }
}


public struct CommunicationPatternContextKey: OptionalContextKey {
    public typealias Value = CommunicationPattern
}

extension HandlerMetadataNamespace {
    /// Name definition for the `ComponentDescriptionMetadata`
    public typealias Pattern = CommunicationPatternMetadata
}

/// The ``CommunicationPatternMetadata`` can be used to explicitly declare a ``Handler``'s
/// ``CommunicationPattern``.
///
/// The framework can automatically detect ``CommunicationPattern/requestResponse`` if the
/// ``Handler/handle()-3440f``'s return type is no ``Response``. If that is not the case and you don't
/// explicitly specify the ``HandlerMetadataNamespace/Pattern``, the ``Handler`` is assumed to use
/// ``CommunicationPattern/bidirectionalStream``.
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
public struct CommunicationPatternMetadata: HandlerMetadataDefinition {
    public typealias Key = CommunicationPatternContextKey
    public let value: CommunicationPattern

    /// Creates a new ``CommunicationPattern`` Metadata
    /// - Parameter pattern: The pattern for the ``Handler``.
    public init(_ pattern: CommunicationPattern) {
        self.value = pattern
    }
}

extension Handler {
    /// A `pattern` Modifier can be used to specify the ``CommunicationPatternMetadata`` via a ``HandlerModifier``.
    /// - Parameter value: The communication pattern of the associated ``Handler``.
    /// - Returns: The modified `Handler` with the `CommunicationPatternMetadata` added.
    public func pattern(_ value: CommunicationPattern) -> HandlerMetadataModifier<Self> {
        HandlerMetadataModifier(modifies: self, with: CommunicationPatternMetadata(value))
    }
}
