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
/// to decode the pattern's ``DecodingPattern/Element``.
public struct PlainPatternStrategy<P: DecodingPattern>: ParameterDecodingStrategy {
    public typealias Content = P.Element
    
    private let decoder: any AnyDecoder
    
    /// Create a new ``PlainPatternStrategy`` that uses the given `decoder`.
    public init(_ decoder: any AnyDecoder) {
        self.decoder = decoder
    }
    
    public func decode(from data: Data) throws -> P.Element {
        try decoder.decode(P.self, from: data).value
    }
}
