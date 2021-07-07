//
//  AllIdentityStrategy.swift
//  
//
//  Created by Max Obermeier on 06.07.21.
//

import Foundation
import Apodini
import ApodiniUtils

/// An ``BaseDecodingStrategy`` that uses a certain `AnyDecoder` to decode each
/// parameter from the given `Data`.
///
/// The strategy expects the `Data` to hold the `Element` at its base.
///
/// E.g. for `Element` being `String`, the following JSON would be a valid input:
///
/// ```json
/// "Max"
/// ```
///
/// - Note: Usage of this strategy only really makes sense if there is only one parameter
/// to be decoded from the given `Data`.
public struct AllIdentityStrategy: BaseDecodingStrategy {
    private let decoder: AnyDecoder
    
    public init(_ decoder: AnyDecoder) {
        self.decoder = decoder
    }
    
    public func strategy<Element, I>(for parameter: I)
        -> AnyParameterDecodingStrategy<Element, Data> where Element: Decodable, I: Identifiable {
        PlainPatternStrategy<IdentityPattern<Element>>(decoder).typeErased
    }
}
