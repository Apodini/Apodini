//
//  MockRequestEndpointDecodingStrategyStrategy.swift
//  
//
//  Created by Paul Schmiedmayer on 7/8/21.
//

import ApodiniExtension


public struct MockRequestEndpointDecodingStrategyStrategy: EndpointDecodingStrategy {
    public init() {}
    
    
    public func strategy<Element: Decodable>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, AnyMockRequest> {
        MockRequestParameterStrategy<Element>(parameter: parameter).typeErased
    }
}


private struct MockRequestParameterStrategy<E: Decodable>: ParameterDecodingStrategy {
    let parameter: EndpointParameter<E>
    
    
    func decode(from request: AnyMockRequest) throws -> E {
        try request.getValue(for: parameter)
    }
}
