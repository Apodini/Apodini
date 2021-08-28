//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import MetadataSystem

/// See `MetadataDefinition` for an explanation on what a Metadata Definition is
/// and a recommendation for a naming convention.
///
/// Any Metadata Definition conforming to `HandlerMetadataDefinition` can be used in
/// the Metadata Declaration Blocks of a `Handler` to annotate the `Handler` with
/// the given Metadata.
///
/// Use the `HandlerMetadataNamespace` to define the name used in the Metadata DSL.
public protocol HandlerMetadataDefinition: MetadataDefinition, AnyHandlerMetadata {}

/// See `MetadataDefinition` for an explanation on what a Metadata Definition is
/// and a recommendation for a naming convention.
///
/// Any Metadata Definition conforming to `ComponentOnlyMetadataDefinition` can be used in
/// the Metadata Declaration Blocks of a `Component` to annotate a `Component` with
/// the given Metadata.
/// `ComponentOnlyMetadataDefinition` cannot be used in the Metadata Declaration Blocks
/// of a `Handler` or the `WebService`. To use a Metadata Definition in all three of
/// those use `ComponentMetadataDefinition`.
///
/// - Note: It is advised to use `ComponentOnlyMetadataDefinition` with care as it doesn't have its
///     own Metadata Namespace. The `ComponentMetadataNamespace` or `ComponentOnlyMetadataNamespace`
///     is still accessible withing `Handler`s and the `WebService`.
public protocol ComponentOnlyMetadataDefinition: MetadataDefinition, AnyComponentOnlyMetadata {}

/// See `MetadataDefinition` for an explanation on what a Metadata Definition is
/// and a recommendation for a naming convention.
///
/// Any Metadata Definition conforming to `WebServiceMetadataDefinition` can be used in
/// the Metadata Declaration Blocks of a `WebService` to annotate the `WebService` with
/// the given Metadata.
///
/// Use the `WebServiceMetadataNamespace` to define the name used in the Metadata DSL.
public protocol WebServiceMetadataDefinition: MetadataDefinition, AnyWebServiceMetadata {}

/// See `MetadataDefinition` for an explanation on what a Metadata Definition is
/// and a recommendation for a naming convention.
///
/// Any Metadata Definition conforming to `ComponentMetadataDefinition` can be used in
/// the Metadata Declaration Blocks of `Component`s to annotate the `Component` with
/// the given Metadata.
/// `ComponentMetadataDefinition`s can be used in the Declaration Blocks of a `Handler` and
/// the `WebService`, as both are `Component`s.
///
/// Use the `ComponentMetadataNamespace` to define the name used in the Metadata DSL.
public protocol ComponentMetadataDefinition: HandlerMetadataDefinition, ComponentOnlyMetadataDefinition,
    WebServiceMetadataDefinition, AnyComponentMetadata {}


public extension ComponentOnlyMetadataDefinition {
    /// By default, `ComponentOnlyMetadataDefinition` will apply to the `Component.Content` as well.
    static var scope: Scope {
        .environment
    }
}

public extension ComponentMetadataDefinition {
    /// By default, `ComponentOnlyMetadataDefinition` will apply to the `Component.Content` as well.
    static var scope: Scope {
        .environment
    }
}
