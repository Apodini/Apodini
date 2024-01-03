//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini

// MARK: Event

/// An ``Event`` describes everything that can be used to
/// evaluate a `Delegate`.
///
/// - Note: A valid sequence of ``Event``s **always** starts with an
/// ``request(_:)`` and it **always** contains exactly **one**
/// ``end``. After the ``end`` only ``trigger(_:)``s may follow.
public enum Event {
    /// A `Request` from the client
    case request(any Request)
    /// A `TriggerEvent` raised by an `ObservedObject`
    case trigger(TriggerEvent)
    /// The signal from the client that it won't send
    /// any more `Request`s
    case end
}
