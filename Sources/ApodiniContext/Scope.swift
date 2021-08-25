//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

/// The scope of a value associated with a ``ContextKey``
public enum Scope {
    /// The value is only applied to the current ``ContextNode`` and discarded afterwards`.
    case current
    /// The value is applied to all following ``ContextNodes``s located in the subtree of the current ``ContextNode``.
    case environment
}
