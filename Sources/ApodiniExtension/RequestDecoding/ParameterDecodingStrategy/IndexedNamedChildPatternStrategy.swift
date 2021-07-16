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
/// - Note: This strategy allows for usage of both ``DynamicNamePattern`` and ``DynamicIndexPattern``.
/// On decoding, the strategy provides the first with its static `name` property. The index required for the
/// ``DynamicIndexPattern`` is obtained from the second field in ``decode(from:)``'s `input`.
public struct IndexedNamedChildPatternStrategy<P: DecodingPattern>: ParameterDecodingStrategy {
    public typealias Content = P.Element

    private let decoder: AnyDecoder
    
    private let name: String

    /// Create a new ``IndexedNamedChildPatternStrategy``.
    ///
    /// - Parameters:
    ///     - `name`:  The name that is provided to the ``DynamicNamePattern`` if that is part of `P`
    ///     - `decoder`: The decoder that is used to decode `P` from the input `Data`
    public init(_ name: String, _ decoder: AnyDecoder) {
        self.name = name
        self.decoder = decoder
    }

    public func decode(from input: (Data, Int)) throws -> P.Element {
        if let nameWrapper = namedChildStrategyFieldName.currentValue {
            nameWrapper.name = name
        } else {
            namedChildStrategyFieldName.currentValue = FieldName(name)
        }
        
        if let indexWrapper = indexStrategyIndex.currentValue {
            indexWrapper.index = input.1
        } else {
            indexStrategyIndex.currentValue = Index(input.1)
        }
        
        return try decoder.decode(P.self, from: input.0).value
    }
}
