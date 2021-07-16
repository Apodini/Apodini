//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Foundation

/// Used to explicitly define the communicational
/// pattern that is expressed by a `Handler`.
public enum ServiceType {
    /// Simple request-response
    case unary
    /// Client-side streaming, service-side unary
    case clientStreaming
    /// Client-side unary, service-side streaming
    case serviceStreaming
    /// Client-side and service-side streaming
    case bidirectional
}

public struct ServiceTypeContextKey: ContextKey {
    public typealias Value = ServiceType
    public static var defaultValue: ServiceType = .unary
}

extension HandlerMetadataNamespace {
    /// Name Definition for the `ServiceTypeHandlerMetadata`
    public typealias ServiceType = ServiceTypeHandlerMetadata
}

/// The `ServiceTypeHandlerMetadata` can be used to explicitly set the name of the gRPC service
/// that is exposed for the given `Handler`.
/// The Metadata is available under the `HandlerMetadataNamespace.ServiceType` name and can be used like the following:
/// ```swift
/// struct ExampleHandler: Handler {
///     // ...
///     var metadata: Metadata {
///         ServiceType(.unary)
///     }
/// }
/// ```
public struct ServiceTypeHandlerMetadata: HandlerMetadataDefinition {
    public typealias Key = ServiceTypeContextKey
    public let value: ServiceType

    /// Creates a new ServiceType Metadata.
    /// - Parameter serviceType: The `ServiceType` for the `Handler`.
    public init(_ serviceType: ServiceType) {
        self.value = serviceType
    }
}

extension Handler {
    /// A `Handler.serviceType(...)` modifier can be used to explicitly specify the `ServiceType` Metadata for the given `Handler`,
    /// setting the name of the gRPC service exposed.
    /// - Parameter serviceType: The `ServiceType` that is applied to the Handler
    /// - Returns: The modified `Handler` with a specified `ServiceType`
    public func serviceType(_ serviceType: Apodini.ServiceType) -> HandlerMetadataModifier<Self> {
        HandlerMetadataModifier(modifies: self, with: ServiceTypeHandlerMetadata(serviceType))
    }
}
