//
//  ParameterTypeSpecific.swift
//  
//
//  Created by Max Obermeier on 06.07.21.
//

import Apodini

/// An ``EndpointDecodingStrategy`` that chooses between two given strategies based
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
    ///     - `type`: The Apodini `ParameterType` for which the `primary` strategy is used
    ///     - `primary`: This strategy is used if the `parameter` is of `type`
    ///     - `backup`: The strategy that is used if the `parameter` is not of `type`
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
