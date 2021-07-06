//
//  Condition.swift
//  
//
//  Created by Lukas Kollmer on 2021-02-06.
//

// swiftlint:disable static_operator


import Foundation
import Apodini
import ApodiniDeployBuildSupport
import ApodiniUtils


/// The `AnyHandlerCondition` type represents some predicate (i.e. a condition) which can be evaluated against a `Handler`.
public class AnyHandlerCondition {
    let predicate: (Any) -> Bool
    
    init<H: Handler>(_: H.Type = H.self, _ predicate: @escaping (H) -> Bool) {
        self.predicate = { predicate(unsafelyCast($0, to: H.self)) }
    }
    
    func test<H: Handler>(on subject: H) -> Bool {
        predicate(subject)
    }
}


public class HandlerCondition<H: Handler>: AnyHandlerCondition {
    init(_: H.Type = H.self, _ predicate: @escaping (H) -> Bool) {
        super.init(H.self, predicate)
    }
    
    // Overriding the superclass initializer and marking it as unavailable to make sure
    // calls to `HandlerCondition.init` don't get dispatched to the superclass initializer.
    // Q: Why is this important?
    // A: The difference between this (overwritten) initializer and the other one in HandlerCondition
    //    is that this one would work for any arbitrary Handler type,
    //    whereas the one above requires the Handler type used in the closure to be the same as the class' generic parameter.
    @available(*, unavailable)
    override init<H: Handler>(_: H.Type = H.self, _ predicate: @escaping (H) -> Bool) {
        fatalError("init(_:_:) is not implemented")
    }
}

/// AND-s two `HandlerCondition`s
public func && <H> (lhs: HandlerCondition<H>, rhs: HandlerCondition<H>) -> HandlerCondition<H> {
    HandlerCondition { lhs.test(on: $0) && rhs.test(on: $0) }
}

/// OR-s two `HandlerCondition`s
public func || <H> (lhs: HandlerCondition<H>, rhs: HandlerCondition<H>) -> HandlerCondition<H> {
    HandlerCondition { lhs.test(on: $0) || rhs.test(on: $0) }
}

/// Negates a `HandlerCondition`
public prefix func ! <H> (rhs: HandlerCondition<H>) -> HandlerCondition<H> {
    HandlerCondition { !rhs.test(on: $0) }
}


extension AnyOption {
    /// Limit the option to only take effect if the specified condition is satisfied
    public func when(_ condition: AnyHandlerCondition) -> AnyOption {
        ConditionalOption(underlyingOption: self, condition: condition)
    }
}


/// Creates a `HandlerCondition` based on an equality check, comparing one of the handler's properties with some value.
public func == <H: Handler, P: Equatable> (lhs: KeyPath<H, P>, rhs: @autoclosure @escaping () -> P) -> HandlerCondition<H> {
    HandlerCondition { $0[keyPath: lhs] == rhs() }
}

/// Creates a `HandlerCondition` based on an inequality check, comparing one of the handler's properties with some value.
public func != <H: Handler, P: Equatable> (lhs: KeyPath<H, P>, rhs: @autoclosure @escaping () -> P) -> HandlerCondition<H> {
    HandlerCondition { $0[keyPath: lhs] != rhs() }
}


/// Creates a `HandlerCondition` based on a less-than comparison, comparing one of the handler's properties with some value.
public func < <H: Handler, P: Comparable> (lhs: KeyPath<H, P>, rhs: @autoclosure @escaping () -> P) -> HandlerCondition<H> {
    HandlerCondition { $0[keyPath: lhs] < rhs() }
}

/// Creates a `HandlerCondition` based on a greater-than comparison, comparing one of the handler's properties with some value.
public func > <H: Handler, P: Comparable> (lhs: KeyPath<H, P>, rhs: @autoclosure @escaping () -> P) -> HandlerCondition<H> {
    HandlerCondition { $0[keyPath: lhs] > rhs() }
}

/// Creates a `HandlerCondition` based on a less-than-or-equal comparison, comparing one of the handler's properties with some value.
public func <= <H: Handler, P: Comparable> (lhs: KeyPath<H, P>, rhs: @autoclosure @escaping () -> P) -> HandlerCondition<H> {
    HandlerCondition { $0[keyPath: lhs] <= rhs() }
}

/// Creates a `HandlerCondition` based on a greater-than-or-equal comparison, comparing one of the handler's properties with some value.
public func >= <H: Handler, P: Comparable> (lhs: KeyPath<H, P>, rhs: @autoclosure @escaping () -> P) -> HandlerCondition<H> {
    HandlerCondition { $0[keyPath: lhs] <= rhs() }
}
