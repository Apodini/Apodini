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

public struct DefaultRequestBasis: RequestBasis {
    private let _description: String?
    private let _debugDescription: String?
    
    public let remoteAddress: SocketAddress?
    public let information: Set<AnyInformation>
    
    public var description: String {
        _description ?? "Request(remoteAddress: \(remoteAddress?.description ?? "nil"), information: \(information))"
    }
    
    public var debugDescription: String {
        _debugDescription ?? "DefaultRequestBasis(remoteAddress: \(remoteAddress?.description ?? "nil"), information: \(information))"
    }
    
    public init(description: String? = nil,
                debugDescription: String? = nil,
                remoteAddress: SocketAddress? = nil,
                information: Set<AnyInformation> = []) {
        self._description = description
        self._debugDescription = debugDescription
        self.remoteAddress = remoteAddress
        self.information = information
    }
    
    public init(base: Any,
                remoteAddress: SocketAddress? = nil,
                information: Set<AnyInformation> = []) {
        self.init(description: (base as? CustomStringConvertible)?.description ?? "\(base)",
                  debugDescription: (base as? CustomDebugStringConvertible)?.debugDescription ?? "\(base)",
                  remoteAddress: remoteAddress,
                  information: information)
    }
}

extension DecodingStrategy {
    public func decodeRequest(from input: Input, with basis: RequestBasis, on eventLoop: EventLoop) -> some Request {
        DecodingRequest(basis: basis, eventLoop: eventLoop, input: input, strategy: self.typeErased)
    }
}

private struct DecodingRequest<Input>: Request {
    let basis: RequestBasis
    
    let eventLoop: EventLoop
    
    let input: Input
    
    let strategy: AnyDecodingStrategy<Input>
    
    func retrieveParameter<Element>(_ parameter: Parameter<Element>) throws -> Element where Element : Decodable, Element : Encodable {
        try strategy.strategy(for: parameter).decode(from: input)
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
    associatedtype Input = Data
    
    func strategy<Element: Decodable>(for parameter: Parameter<Element>) -> AnyParameterDecodingStrategy<Element, Input>
}

public protocol EndpointDecodingStrategy {
    associatedtype Input = Data
    
    func strategy<Element: Decodable>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, Input>
}

public protocol BaseDecodingStrategy: DecodingStrategy, EndpointDecodingStrategy {
    associatedtype Input = Data
    
    func strategy<Element: Decodable, I: Identifiable>(for parameter: I) -> AnyParameterDecodingStrategy<Element, Input> where I.ID == UUID
}


public extension DecodingStrategy {
    var typeErased: AnyDecodingStrategy<Input> {
        AnyDecodingStrategy(self)
    }
}

public struct AnyDecodingStrategy<I>: DecodingStrategy {
    private let caller: DecodingStrategyCaller
    
    
    init<S: DecodingStrategy>(_ strategy: S) where S.Input == I {
        self.caller = SomeDecodingStrategyCaller(strategy: strategy)
    }
    
    
    public func strategy<Element>(for parameter: Parameter<Element>) -> AnyParameterDecodingStrategy<Element, I> where Element : Decodable, Element : Encodable {
        caller.call(with: parameter)
    }
}

private protocol DecodingStrategyCaller {
    func call<E: Decodable, I>(with parameter: Parameter<E>) -> AnyParameterDecodingStrategy<E, I>
}

private struct SomeDecodingStrategyCaller<S: DecodingStrategy>: DecodingStrategyCaller {
    let strategy: S
    
    func call<E: Decodable, I>(with parameter: Parameter<E>) -> AnyParameterDecodingStrategy<E, I> {
        guard let parameterStrategy = strategy.strategy(for: parameter) as? AnyParameterDecodingStrategy<E, I> else {
            fatalError("'SomeDecodingStrategyCaller' was used with wrong input type (\(I.self) instead of \(S.Input.self))")
        }
        return parameterStrategy
    }
}


public extension EndpointDecodingStrategy {
    var typeErased: AnyEndpointDecodingStrategy<Input> {
        AnyEndpointDecodingStrategy(self)
    }
}

public struct AnyEndpointDecodingStrategy<I>: EndpointDecodingStrategy {
    private let caller: EndpointDecodingStrategyCaller
    
    
    init<S: EndpointDecodingStrategy>(_ strategy: S) where S.Input == I {
        self.caller = SomeEndpointDecodingStrategyCaller(strategy: strategy)
    }
    
    
    public func strategy<Element>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, I> where Element : Decodable, Element : Encodable {
        caller.call(with: parameter)
    }
}

private protocol EndpointDecodingStrategyCaller {
    func call<E: Decodable, I>(with parameter: EndpointParameter<E>) -> AnyParameterDecodingStrategy<E, I>
}

private struct SomeEndpointDecodingStrategyCaller<S: EndpointDecodingStrategy>: EndpointDecodingStrategyCaller {
    let strategy: S
    
    func call<E: Decodable, I>(with parameter: EndpointParameter<E>) -> AnyParameterDecodingStrategy<E, I> {
        guard let parameterStrategy = strategy.strategy(for: parameter) as? AnyParameterDecodingStrategy<E, I> else {
            fatalError("'SomeEndpointDecodingStrategyCaller' was used with wrong input type (\(I.self) instead of \(S.Input.self))")
        }
        return parameterStrategy
    }
}


public struct AnyBaseDecodingStrategy<Input>: BaseDecodingStrategy {
    private let caller: BaseDecodingStrategyCaller
    
    
    init<S: BaseDecodingStrategy>(_ strategy: S) where S.Input == Input {
        self.caller = SomeBaseDecodingStrategyCaller(strategy: strategy)
    }
    
    public func strategy<Element, I>(for parameter: I) -> AnyParameterDecodingStrategy<Element, Data> where Element : Decodable, I : Identifiable, I.ID == UUID {
        caller.call(with: parameter)
    }
}

private protocol BaseDecodingStrategyCaller {
    func call<E: Decodable, I, ID: Identifiable>(with parameter: ID) -> AnyParameterDecodingStrategy<E, I> where ID.ID == UUID
}

private struct SomeBaseDecodingStrategyCaller<S: BaseDecodingStrategy>: BaseDecodingStrategyCaller {
    let strategy: S
    
    func call<E: Decodable, I, ID: Identifiable>(with parameter: ID) -> AnyParameterDecodingStrategy<E, I> where ID.ID == UUID {
        let untypedParameterStrategy: AnyParameterDecodingStrategy<E, S.Input> = strategy.strategy(for: parameter)
        guard let parameterStrategy = untypedParameterStrategy as? AnyParameterDecodingStrategy<E, I> else {
            fatalError("'SomeBaseDecodingStrategyCaller' was used with wrong input type (\(I.self) instead of \(S.Input.self))")
        }
        return parameterStrategy
    }
}


extension BaseDecodingStrategy {
    public func strategy<Element>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, Input> where Element : Decodable, Element : Encodable {
        self.strategy(parameter)
    }
    
    public func strategy<Element>(for parameter: Parameter<Element>) -> AnyParameterDecodingStrategy<Element, Input> where Element : Decodable, Element : Encodable {
        self.strategy(parameter)
    }
    
    private func strategy<I: Identifiable, Element: Decodable>(_ parameter: I) -> AnyParameterDecodingStrategy<Element, Input> where I.ID == UUID {
        self.strategy(for: parameter)
    }
}


extension EndpointDecodingStrategy {
    public func applied(to endpoint: AnyEndpoint) -> AnyDecodingStrategy<Input> {
        EndpointParameterBasedDecodingStrategy(self, on: endpoint).typeErased
    }
}


private struct EndpointParameterBasedDecodingStrategy<S: EndpointDecodingStrategy>: DecodingStrategy {
    private let strategy: S
    
    private let endpointParameters: [UUID: AnyEndpointParameter]
    
    init(_ strategy: S, on endpoint: AnyEndpoint) {
        self.strategy = strategy
        self.endpointParameters = endpoint[EndpointParametersById.self].parameters
    }
    
    func strategy<Element: Decodable>(for parameter: Parameter<Element>) -> AnyParameterDecodingStrategy<Element, S.Input> {
        guard let parameter = endpointParameters[parameter.id] as? CanCallEndpointParameterDecodingStrategy else {
            fatalError("Couldn't find matching 'EndpointParameter' with id \(parameter.id) while determining 'ParsingStrategy'.")
        }
        
        return parameter.call(strategy)
    }
}

private protocol CanCallEndpointParameterDecodingStrategy {
    func call<S: EndpointDecodingStrategy, Element: Decodable, Input>(_ strategy: S) -> AnyParameterDecodingStrategy<Element, Input>
}

extension EndpointParameter: CanCallEndpointParameterDecodingStrategy {
    func call<S, V, I>(_ strategy: S) -> AnyParameterDecodingStrategy<V, I> where S : EndpointDecodingStrategy, V : Decodable {
        let baseStrategy = strategy.strategy(for: self)
        if nilIsValidValue { // V == Optional<Type>
            if let typedStrategy = OptionalWrappingStrategy(baseStrategy: baseStrategy).typeErased as? AnyParameterDecodingStrategy<V, I> {
                return typedStrategy
            }
            fatalError("Internal logic of 'EndpointParameter.call(_:)' is broken: wrong type in nil case.")
        } else { // V == Type
            if let typedStrategy = baseStrategy as? AnyParameterDecodingStrategy<V, I> {
                return typedStrategy
            }
            fatalError("Internal logic of 'EndpointParameter.call(_:)' is broken: wrong type in base case.")
        }
    }
}

private struct OptionalWrappingStrategy<P: ParameterDecodingStrategy>: ParameterDecodingStrategy {
    let baseStrategy: P
    
    func decode(from input: P.Input) throws -> Optional<P.Element> {
        do {
            return .some(try baseStrategy.decode(from: input))
        } catch DecodingError.valueNotFound(_, _) {
            return .none
        }
    }
}

// MARK: ParameterDecodingStrategy

public protocol ParameterDecodingStrategy {
    associatedtype Element: Decodable
    associatedtype Input = Data
    
    func decode(from input: Input) throws -> Element
}

public extension ParameterDecodingStrategy {
    var typeErased: AnyParameterDecodingStrategy<Element, Input> {
        AnyParameterDecodingStrategy(self)
    }
}

public struct AnyParameterDecodingStrategy<E: Decodable, I>: ParameterDecodingStrategy {
    private let _decode: (I) throws -> E
    
    internal init<S: ParameterDecodingStrategy>(_ strategy: S) where S.Element == E, S.Input == I {
        self._decode = strategy.decode
    }
    
    public func decode(from input: I) throws -> E {
        try _decode(input)
    }
}
