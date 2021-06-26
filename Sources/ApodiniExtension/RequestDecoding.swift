//
//  RequestDecoding.swift
//  
//
//  Created by Max Obermeier on 24.06.21.
//

import Foundation
import OpenCombine
import Apodini
import ApodiniUtils

// MARK: RequestBasis
public protocol RequestBasis {
    /// Returns a description of the Request.
    var description: String { get }
    /// Returns a debug description of the Request.
    var debugDescription: String { get }

    var remoteAddress: SocketAddress? { get }
    
    var information: Set<AnyInformation> { get }
}

extension AnyDecoder {
    func decodeRequest<P: DecodingStrategy>(from data: Data?, using strategy: P, with basis: RequestBasis, on eventLoop: EventLoop) -> some Request {
        DecodingRequest(basis: basis, eventLoop: eventLoop, data: data ?? Data(), decoder: self, strategy: strategy)
    }
}

private struct DecodingRequest: Request {
    let basis: RequestBasis
    
    let eventLoop: EventLoop
    
    let data: Data
    
    let decoder: AnyDecoder
    
    let strategy: DecodingStrategy
    
    func retrieveParameter<Element>(_ parameter: Parameter<Element>) throws -> Element where Element : Decodable, Element : Encodable {
        try strategy.strategy(for: parameter).decode(from: data)
    }
    
    var description: String {
        basis.description
    }
    
    var debugDescription: String {
        basis.debugDescription
    }
    
    var remoteAddress: SocketAddress? {
        basis.remoteAddress
    }
    
    var information: Set<AnyInformation> {
        basis.information
    }
}


// MARK: DecodingStrategy

public protocol DecodingStrategy {
    func strategy<Element: Decodable>(for parameter: Parameter<Element>) -> AnyParameterDecodingStrategy<Element>
}

public protocol EndpointDecodingStrategy {
    func strategy<Element: Decodable>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element>
}

public protocol BaseDecodingStrategy: DecodingStrategy, EndpointDecodingStrategy {
    func strategy<Element: Decodable, I: Identifiable>(for parameter: I) -> AnyParameterDecodingStrategy<Element> where I.ID == UUID
}


extension EndpointDecodingStrategy {
    func applied(to endpoint: AnyEndpoint) -> DecodingStrategy {
        EndpointParameterBasedDecodingStrategy(self, on: endpoint)
    }
}


extension BaseDecodingStrategy {
    public func strategy<Element>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element> where Element : Decodable, Element : Encodable {
        self.strategy(for: parameter)
    }
    
    public func strategy<Element>(for parameter: Parameter<Element>) -> AnyParameterDecodingStrategy<Element> where Element : Decodable, Element : Encodable {
        self.strategy(for: parameter)
    }
}


private struct EndpointParameterBasedDecodingStrategy<S: EndpointDecodingStrategy>: DecodingStrategy {
    private let strategy: S
    
    private let endpointParameters: [UUID: AnyEndpointParameter]
    
    init(_ strategy: S, on endpoint: AnyEndpoint) {
        self.strategy = strategy
        self.endpointParameters = endpoint[EndpointParameters.self].reduce(into: [UUID: AnyEndpointParameter](), { storage, parameter in
            storage[parameter.id] = parameter
        })
    }
    
    func strategy<Element: Decodable>(for parameter: Parameter<Element>) -> AnyParameterDecodingStrategy<Element> {
        guard let parameter = endpointParameters[parameter.id] as? CanCallEndpointParameterDecodingStrategy else {
            fatalError("Couldn't find matching 'EndpointParameter' with id \(parameter.id) while determining 'ParsingStrategy'.")
        }
        
        return parameter.call(strategy)
    }
}

private protocol CanCallEndpointParameterDecodingStrategy {
    func call<S: EndpointDecodingStrategy, Element: Decodable>(_ strategy: S) -> AnyParameterDecodingStrategy<Element>
}

extension EndpointParameter: CanCallEndpointParameterDecodingStrategy {
    func call<S, V>(_ strategy: S) -> AnyParameterDecodingStrategy<V> where S : EndpointDecodingStrategy, V : Decodable {
        let baseStrategy = strategy.strategy(for: self)
        if nilIsValidValue { // V == Optional<Type>
            if let typedStrategy = OptionalWrappingStrategy(baseStrategy: baseStrategy).typeErased as? AnyParameterDecodingStrategy<V> {
                return typedStrategy
            }
            fatalError("Internal logic of 'EndpointParameter.call(_:)' is broken: wrong type in nil case.")
        } else { // V == Type
            if let typedStrategy = baseStrategy as? AnyParameterDecodingStrategy<V> {
                return typedStrategy
            }
            fatalError("Internal logic of 'EndpointParameter.call(_:)' is broken: wrong type in base case.")
        }
    }
}

private struct OptionalWrappingStrategy<P: ParameterDecodingStrategy>: ParameterDecodingStrategy {
    let baseStrategy: P
    
    func decode(from data: Data) throws -> Optional<P.Element> {
        do {
            return .some(try baseStrategy.decode(from: data))
        } catch DecodingError.valueNotFound(_, _) {
            return .none
        }
    }
}

// MARK: ParameterDecodingStrategy

public protocol ParameterDecodingStrategy {
    associatedtype Element: Decodable
    
    func decode(from data: Data) throws -> Element
}

public extension ParameterDecodingStrategy {
    var typeErased: AnyParameterDecodingStrategy<Element> {
        AnyParameterDecodingStrategy(self)
    }
}

public struct AnyParameterDecodingStrategy<E: Decodable>: ParameterDecodingStrategy {
    private let _decode: (Data) throws -> E
    
    internal init<S: ParameterDecodingStrategy>(_ strategy: S) where S.Element == E {
        self._decode = strategy.decode
    }
    
    public func decode(from data: Data) throws -> E {
        try _decode(data)
    }
}

extension String: CodingKey {
    public init?(intValue: Int) {
        self = String(describing: intValue)
    }
    
    public init?(stringValue: String) {
        self = stringValue
    }
    
    public var stringValue: String {
        self
    }
    
    public var intValue: Int? {
        Int(self)
    }
}
