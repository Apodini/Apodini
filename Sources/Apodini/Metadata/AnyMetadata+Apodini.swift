//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import MetadataSystem

/// `AnyHandlerMetadata` represents arbitrary Metadata that can be declared on `Handler`s.
public protocol AnyHandlerMetadata: AnyMetadata {}
/// `AnyComponentOnlyMetadata` represents arbitrary Metadata that can be declared on `Component` only,
/// meaning on all `Component`s  which are **not** `Handler`s or the `WebService`.
public protocol AnyComponentOnlyMetadata: AnyMetadata {}
/// AnyWebServiceMetadata` represents arbitrary Metadata that can be declared on the `WebService`.
public protocol AnyWebServiceMetadata: AnyMetadata {}

/// `AnyComponentMetadata` represents arbitrary Metadata that can be declared on `Component`s.
/// Such Metadata can also be used on `Handler`s and on the `WebService` which both are Components as well,
/// as it inherits from `AnyHandlerMetadata`, `AnyWebServiceMetadata` and `AnyComponentOnlyMetadata`.
public protocol AnyComponentMetadata: AnyComponentOnlyMetadata, AnyHandlerMetadata, AnyWebServiceMetadata {}
