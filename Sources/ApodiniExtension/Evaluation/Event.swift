//
//  Event.swift
//  
//
//  Created by Max Obermeier on 06.07.21.
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
    case request(Request)
    /// A `TriggerEvent` raised by an `ObservedObject`
    case trigger(TriggerEvent)
    /// The signal from the client that it won't send
    /// any more `Request`s
    case end
}
