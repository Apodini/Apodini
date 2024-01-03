//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
    
    private let decoder: any AnyDecoder
    
    /// Create a new ``NamedChildPatternStrategy``.
    ///
    /// - Parameters:
    ///     - `name`:  The name that is provided to the ``DynamicNamePattern`` if that is part of `P`
    ///     - `decoder`: The decoder that is used to decode `P` from the input `Data`
    public init(_ name: String, _ decoder: any AnyDecoder) {
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
