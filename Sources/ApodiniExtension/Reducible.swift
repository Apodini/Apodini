//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation

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

public extension AsyncSequence where Element: Reducible {
    /// This `AsyncSequence` implements a reduction on a type `R` that can be created from the
    /// upstream's output. Each incoming value is mapped to the current accumulated result of the reduction.
    func reduce() -> AsyncMapSequence<Self, Element> where Element.Input == Element {
        var last: Element?
        
        return self.map { (new: Element) -> Element in
            let result = last?.reduce(with: new) ?? new
            last = result
            return result
        }
    }
}

public extension AsyncSequence {
    /// This `AsyncSequence` implements a reduction on a type `R` that can be created from the
    /// upstream's output. Each incoming value is mapped to the current accumulated result of the reduction.
    func reduce<R: Initializable>(_ type: R.Type = R.self) -> AsyncMapSequence<Self, R> where Element == R.Input {
        var last: R?
        
        return self.map { (new: Element) -> R in
            let result = last?.reduce(with: new) ?? R(new)
            last = result
            return result
        }
    }
}
