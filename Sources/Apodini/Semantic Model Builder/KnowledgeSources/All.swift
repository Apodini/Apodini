//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// A ``KnowledgeSource`` that provides access to all properties of a certain
/// type defined on the ``Handler`` associated with this endpoint.
///
/// This ``KnowledgeSource`` uses the same method to inspect the ``Handler`` as
/// the framework. It only finds properties that are directly placed on the ``Handler``
/// associated with this endpoint, properties nested in ``DynamicProperty``s,
/// ``Properties`` or ``Delegate``.
///
/// - Note: While ``T`` could be anything, it is intended to be a ``Property``.
public struct All<T>: HandlerKnowledgeSource {
    /// The gathered properties with their name.
    ///
    /// - Note: The name is by default the property's tag at the lowest level,
    /// but may be overridden using e.g. ``DynamicProperty/namingStrategy(_:)-5rml4``
    public let elements: [(String, T)]
    
    public init<H, B>(from handler: H, _ sharedRepository: B) throws where H: Handler, B: SharedRepository {
        self.elements = getAll(of: T.self, from: handler)
    }
}
