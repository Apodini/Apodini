//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 2021-02-06.
//

import Foundation
import ApodiniDeployBuildSupport


public struct AnyCondition {
    let predicate: (Any) -> Bool
    
    init<H: Handler>(_: H.Type = H.self, _ predicate: @escaping (H) -> Bool) {
        self.predicate = { predicate($0 as! H) }
    }
    
    func test<H: Handler>(on subject: H) -> Bool {
        return predicate(subject)
    }
}


extension AnyOption {
    /// Limit the option to only take effect if the specified condition is satisfied
    public func when(_ condition: AnyCondition) -> AnyOption {
        ConditionalOption(underlyingOption: self, condition: condition)
    }
}


public func == <H: Handler, P: Equatable> (lhs: KeyPath<H, P>, rhs: P) -> AnyCondition {
    AnyCondition(H.self) { $0[keyPath: lhs] == rhs }
}

public func != <H: Handler, P: Equatable> (lhs: KeyPath<H, P>, rhs: P) -> AnyCondition {
    AnyCondition(H.self) { $0[keyPath: lhs] != rhs }
}


public func < <H: Handler, P: Comparable> (lhs: KeyPath<H, P>, rhs: P) -> AnyCondition {
    AnyCondition(H.self) { $0[keyPath: lhs] < rhs }
}

public func > <H: Handler, P: Comparable> (lhs: KeyPath<H, P>, rhs: P) -> AnyCondition {
    AnyCondition(H.self) { $0[keyPath: lhs] > rhs }
}

public func <= <H: Handler, P: Comparable> (lhs: KeyPath<H, P>, rhs: P) -> AnyCondition {
    AnyCondition(H.self) { $0[keyPath: lhs] <= rhs }
}

public func >= <H: Handler, P: Comparable> (lhs: KeyPath<H, P>, rhs: P) -> AnyCondition {
    AnyCondition(H.self) { $0[keyPath: lhs] <= rhs }
}
