//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 2021-02-06.
//

import Foundation
import Apodini
import ApodiniDeployBuildSupport


public class AnyHandlerCondition {
    let predicate: (Any) -> Bool
    
    init<H: Handler>(_: H.Type = H.self, _ predicate: @escaping (H) -> Bool) {
        self.predicate = { predicate($0 as! H) }
    }
    
    func test<H: Handler>(on subject: H) -> Bool {
        return predicate(subject)
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
    override init<H>(_: H.Type = H.self, _ predicate: @escaping (H) -> Bool) where H : Handler {
        fatalError("init(_:_:) is not implemented")
    }
}

public func && <H> (lhs: HandlerCondition<H>, rhs: HandlerCondition<H>) -> HandlerCondition<H> {
    HandlerCondition { lhs.test(on: $0) && rhs.test(on: $0) }
}

public func || <H> (lhs: HandlerCondition<H>, rhs: HandlerCondition<H>) -> HandlerCondition<H> {
    HandlerCondition { lhs.test(on: $0) || rhs.test(on: $0) }
}

public prefix func ! <H> (rhs: HandlerCondition<H>) -> HandlerCondition<H> {
    return HandlerCondition { !rhs.test(on: $0) }
}


extension AnyOption {
    /// Limit the option to only take effect if the specified condition is satisfied
    public func when(_ condition: AnyHandlerCondition) -> AnyOption {
        ConditionalOption(underlyingOption: self, condition: condition)
    }
}


public func == <H: Handler, P: Equatable> (lhs: KeyPath<H, P>, rhs: @autoclosure @escaping () -> P) -> HandlerCondition<H> {
    HandlerCondition { $0[keyPath: lhs] == rhs() }
}

public func != <H: Handler, P: Equatable> (lhs: KeyPath<H, P>, rhs: @autoclosure @escaping () -> P) -> HandlerCondition<H> {
    HandlerCondition { $0[keyPath: lhs] != rhs() }
}


public func < <H: Handler, P: Comparable> (lhs: KeyPath<H, P>, rhs: @autoclosure @escaping () -> P) -> HandlerCondition<H> {
    HandlerCondition { $0[keyPath: lhs] < rhs() }
}

public func > <H: Handler, P: Comparable> (lhs: KeyPath<H, P>, rhs: @autoclosure @escaping () -> P) -> HandlerCondition<H> {
    HandlerCondition { $0[keyPath: lhs] > rhs() }
}

public func <= <H: Handler, P: Comparable> (lhs: KeyPath<H, P>, rhs: @autoclosure @escaping () -> P) -> HandlerCondition<H> {
    HandlerCondition { $0[keyPath: lhs] <= rhs() }
}

public func >= <H: Handler, P: Comparable> (lhs: KeyPath<H, P>, rhs: @autoclosure @escaping () -> P) -> HandlerCondition<H> {
    HandlerCondition { $0[keyPath: lhs] <= rhs() }
}
