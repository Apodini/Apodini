//
//  AllNamedStrategy.swift
//  
//
//  Created by Max Obermeier on 06.07.21.
//

import Foundation
import ApodiniUtils
import Apodini

/// An ``EndpointDecodingStrategy`` that uses a certain `AnyDecoder` to decode each
/// parameter based on the parameters name.
///
/// The strategy expects the `Data` to hold a `String`-keyed container as its base element.
/// The returned ``ParameterDecodingStrategy`` tries to decode the `Element` from
/// the container that is keyed by `parameter/name`.
///
/// E.g. for `Element` being `String` and the parameter's name being `"name"`, the following JSON
/// would be a valid input:
///
/// ```json
/// {
///     "name": "Max"
/// }
/// ```
public struct AllNamedStrategy: EndpointDecodingStrategy {
    private let decoder: AnyDecoder
    
    public init(_ decoder: AnyDecoder) {
        self.decoder = decoder
    }
    
    public func strategy<Element>(for parameter: EndpointParameter<Element>)
        -> AnyParameterDecodingStrategy<Element, Data> where Element: Decodable, Element: Encodable {
        NamedChildPatternStrategy<DynamicNamePattern<IdentityPattern<Element>>>(parameter.name, decoder).typeErased
    }
}
