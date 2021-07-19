//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Apodini
import ApodiniUtils

// MARK: ParameterDecodingStrategy

/// A strategy that can decode a certain ``Element`` from a certain ``Input``.
///
/// A ``ParameterDecodingStrategy`` carries the relevant information about
/// a certain parameter and uses this information when its ``decode(from:)`` method
/// is called to obtain an instance of ``Element`` from the given instance of ``Input``.
public protocol ParameterDecodingStrategy {
    /// The type this strategy can instantiate.
    associatedtype Element: Decodable
    /// The type this strategy requires to instantiate an ``Element``
    associatedtype Input = Data
    
    /// This function instantiates a type of ``ParameterDecodingStrategy/Element`` from the given `input`.
    func decode(from input: Input) throws -> Element
}


// MARK: AnyParameterDecodingStrategy

public extension ParameterDecodingStrategy {
    /// Erases the type from this ``ParameterDecodingStrategy``.
    var typeErased: AnyParameterDecodingStrategy<Element, Input> {
        AnyParameterDecodingStrategy(self)
    }
}

/// A type-erased wrapper around any ``ParameterDecodingStrategy``.
public struct AnyParameterDecodingStrategy<E: Decodable, I>: ParameterDecodingStrategy {
    private let _decode: (I) throws -> E
    
    internal init<S: ParameterDecodingStrategy>(_ strategy: S) where S.Element == E, S.Input == I {
        self._decode = strategy.decode
    }
    
    public func decode(from input: I) throws -> E {
        try _decode(input)
    }
}


// MARK: TransformingStrategy

/// A ``ParameterDecodingStrategy`` that forms a transition between a wrapped ``ParameterDecodingStrategy`` `S`
/// and a parent ``ParameterDecodingStrategy`` with ``ParameterDecodingStrategy/Input`` type `I`.
///
/// This strategy allows for reuse of ``ParameterDecodingStrategy`` with a more basic ``ParameterDecodingStrategy/Input`` than
/// the one you are actually using. E.g. many of the predefined strategies have input type `Data`.
/// If your input type is a complete request, you can probably reuse those predefined strategies by extracting the body
/// from the request.
public struct TransformingParameterStrategy<S: ParameterDecodingStrategy, I>: ParameterDecodingStrategy {
    private let transformer: (I) throws -> S.Input
    private let strategy: S
    
    /// Create a new ``TransformingParameterStrategy`` from the given `strategy` by providing a
    /// `transformer` which can extract the `strategy`'s ``ParameterDecodingStrategy/Input`` from
    /// a more general new ``ParameterDecodingStrategy/Input`` type `I`.
    public init(_ strategy: S, using transformer: @escaping (I) throws -> S.Input) {
        self.strategy = strategy
        self.transformer = transformer
    }
    
    public func decode(from input: I) throws -> S.Element {
        try strategy.decode(from: transformer(input))
    }
}
