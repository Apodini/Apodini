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

/// A ``BaseDecodingStrategy`` that chooses a different ``ParameterDecodingStrategy`` based
/// on the `parameter`'s `id`.
public struct IdentifierBasedStrategy<Input>: BaseDecodingStrategy {
    private var strategies = [UUID: Any]()
    
    /// Create an empty ``IdentifierBasedStrategy`` that is still to be filled with the actual
    /// strategies using ``IdentifierBasedStrategy/with(strategy:for:)``.
    ///
    /// - Warning: If not filled with a strategy for each relevant parameter, this strategy crashes on runtime!
    public init() {}
    
    public func strategy<Element, I>(for parameter: I)
        -> AnyParameterDecodingStrategy<Element, Input> where Element: Decodable, I: Identifiable, I.ID == UUID {
        guard let strategy = strategies[parameter.id] as? AnyParameterDecodingStrategy<Element, Input> else {
            fatalError("'IdentifierBasedStrategy' is missing strategy for parameter with id \(parameter.id)!")
        }
        return strategy
    }
    
    /// Add a certain `strategy` to be used for decoding `parameter`.
    public func with<P: ParameterDecodingStrategy, I: Identifiable>(strategy: P, for parameter: I)
        -> Self where I.ID == UUID, P.Input == Input {
        var selfCopy = self
        selfCopy.strategies[parameter.id] = strategy.typeErased
        return selfCopy
    }
}
