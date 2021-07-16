//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini

/// An ``EndpointDecodingStrategy`` that chooses between three given strategies based
/// on the `parameter`'s `parameterType`.
public struct ParameterTypeSpecific<
    L: EndpointDecodingStrategy,
    P: EndpointDecodingStrategy,
    C: EndpointDecodingStrategy>: EndpointDecodingStrategy where L.Input == P.Input, P.Input == C.Input {
    private let lightweight: L
    private let path: P
    private let content: C
    
    /// Create an ``EndpointDecodingStrategy`` that uses different strategies based on the `parameter`'s
    /// `parameterType`.
    ///
    /// - Parameters:
    ///     - `lightweight`: The strategy to be used if the parameter is of `parameterType` `lightweight`
    ///     - `path`:  The strategy to be used if the parameter is of `parameterType` `path`
    ///     - `content`: The strategy to be used if the parameter is of `parameterType` `content`
    public init(lightweight: L, path: P, content: C) {
        self.lightweight = lightweight
        self.path = path
        self.content = content
    }
    
    public func strategy<Element>(for parameter: EndpointParameter<Element>)
        -> AnyParameterDecodingStrategy<Element, L.Input> where Element: Decodable, Element: Encodable {
        switch parameter.parameterType {
        case .lightweight:
            return lightweight.strategy(for: parameter)
        case .path:
            return path.strategy(for: parameter)
        case .content:
            return content.strategy(for: parameter)
        }
    }
}
