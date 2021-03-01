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
