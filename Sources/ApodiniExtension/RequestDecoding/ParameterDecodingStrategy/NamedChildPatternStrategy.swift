//
//  NamedChildPatternStrategy.swift
//  
//
//  Created by Max Obermeier on 06.07.21.
//

import Foundation
import ApodiniUtils

/// A ``ParameterDecodingStrategy`` that uses a certain `AnyDecoder` and a ``DecodingPattern``
/// to decode the pattern's ``DecodingPattern/Element`` just as ``PlainPatternStrategy``.
///
/// - Note: This strategy allows for usage of ``DynamicNamePattern``. On decoding, the strategy provides
/// this pattern with its `name` property.
public struct NamedChildPatternStrategy<P: DecodingPattern>: ParameterDecodingStrategy {
    public typealias Content = P.Element
    
    private let name: String
    
    private let decoder: AnyDecoder
    
    /// Create a new ``NamedChildPatternStrategy``.
    ///
    /// - Parameters:
    ///     - `name`:  The name that is provided to the ``DynamicNamePattern`` if that is part of `P`
    ///     - `decoder`: The decoder that is used to decode `P` from the input `Data`
    public init(_ name: String, _ decoder: AnyDecoder) {
        self.name = name
        self.decoder = decoder
    }
    
    public func decode(from data: Data) throws -> P.Element {
        if let nameWrapper = namedChildStrategyFieldName.currentValue {
            nameWrapper.name = name
        } else {
            namedChildStrategyFieldName.currentValue = FieldName(name)
        }
        return try decoder.decode(P.self, from: data).value
    }
}
