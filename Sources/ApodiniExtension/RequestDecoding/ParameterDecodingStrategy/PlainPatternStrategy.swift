//
//  PlainPatternStrategy.swift
//  
//
//  Created by Max Obermeier on 06.07.21.
//

import Foundation
import ApodiniUtils

/// A ``ParameterDecodingStrategy`` that uses a certain `AnyDecoder` and a ``DecodingPattern``
/// to decode the pattern's ``DecodingPattern/Element``.
public struct PlainPatternStrategy<P: DecodingPattern>: ParameterDecodingStrategy {
    public typealias Content = P.Element
    
    private let decoder: AnyDecoder
    
    /// Create a new ``PlainPatternStrategy`` that uses the given `decoder`.
    public init(_ decoder: AnyDecoder) {
        self.decoder = decoder
    }
    
    public func decode(from data: Data) throws -> P.Element {
        try decoder.decode(P.self, from: data).value
    }
}
