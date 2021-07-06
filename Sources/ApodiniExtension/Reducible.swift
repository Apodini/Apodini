//
//  Reducible.swift
//  
//
//  Created by Max Obermeier on 06.07.21.
//

import Foundation
import OpenCombine

/// An object that can merge itself and a `new` element
/// of same type.
public protocol Reducible {
    /// The input type for the ``Reducible/reduce(with:)`` function.
    associatedtype Input
    
    /// Called to reduce self with the given instance.
    ///
    /// Optional to implement. By default new will overwrite the existing instance.
    ///
    /// - Parameter new: The instance to be combined with.
    /// - Returns: The reduced instance.
    func reduce(with new: Input) -> Self
}

/// A ``Reducible`` type where a initial instance can be obtained
/// from an instance of its ``Reducible/Input`` type.
public protocol Initializable: Reducible {
    /// Initialize an initial instance from the ``Reducible/Input`` that
    /// can be reduced afterwards.
    init(_ initial: Input)
}

public extension Publisher where Output: Reducible {
    /// This publisher implements a reduction on the upstream's output. For each
    /// incoming value, the current result of the reduction is published.
    func reduce() -> OpenCombine.Publishers.Map<Self, Output> where Output.Input == Output {
        var last: Output?
        
        return self.map { (new: Output) -> Output in
            let result = last?.reduce(with: new) ?? new
            last = result
            return result
        }
    }
}

public extension Publisher {
    /// This publisher implements a reduction on a type `R` that can be created from the
    /// upstream's output. For each incoming value, the current result of the reduction is published.
    func reduce<R: Initializable>(_ type: R.Type = R.self) -> OpenCombine.Publishers.Map<Self, R> where Output == R.Input {
        var last: R?
        
        return self.map { (new: Output) -> R in
            let result = last?.reduce(with: new) ?? R(new)
            last = result
            return result
        }
    }
}
