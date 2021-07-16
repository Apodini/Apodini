//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Foundation
import ApodiniUtils
import Apodini

/// A ``EndpointDecodingStrategy`` that chooses between either of two strategies depending on the
/// number of parameters on the given `endpoint` that have type Apodini `ParameterType/content`.
public struct NumberOfContentParameterAwareStrategy<Input>: EndpointDecodingStrategy {
    private let strategy: AnyEndpointDecodingStrategy<Input>
    
    /// Create a ``EndpointDecodingStrategy`` that chooses a different strategy depending on the
    /// number of content parameters on the associated endpoint.
    ///
    /// - Parameters:
    ///     - `endpoint`: The associated Apodini `Endpoint`
    ///     - `one`: The strategy that is used if `endpoint` has one or zero parameters with `ParameterType/content`
    ///     - `many`: The strategy that is used if `endpoint` has more than one parameter with `ParameterType/content`
    public init<One: EndpointDecodingStrategy, Many: EndpointDecodingStrategy>(
        for endpoint: AnyEndpoint,
        using one: One,
        or many: Many) where One.Input == Input, Many.Input == Input {
        let onlyOneContentParameter = 1 <= endpoint[EndpointParameters.self].reduce(0, { count, parameter in
            count + (parameter.parameterType == .content ? 1 : 0)
        })
                                            
        if onlyOneContentParameter {
            self.strategy = one.typeErased
        } else {
            self.strategy = many.typeErased
        }
    }
    
    public func strategy<Element>(for parameter: EndpointParameter<Element>)
        -> AnyParameterDecodingStrategy<Element, Input> where Element: Decodable, Element: Encodable {
        strategy.strategy(for: parameter)
    }
}

public extension NumberOfContentParameterAwareStrategy where Input == Data {
    /// An instance of ``NumberOfContentParameterAwareStrategy`` that chooses between
    /// ``AllIdentityStrategy`` and ``AllNamedStrategy``.
    static func oneIdentityOrAllNamedContentStrategy(_ decoder: AnyDecoder, for endpoint: AnyEndpoint) -> Self {
        self.init(for: endpoint, using: AllIdentityStrategy(decoder), or: AllNamedStrategy(decoder))
    }
}
