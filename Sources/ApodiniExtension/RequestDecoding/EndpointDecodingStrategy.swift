//
//  EndpointDecodingStrategy.swift
//  
//
//  Created by Max Obermeier on 28.06.21.
//

import Foundation
import Apodini
import ApodiniUtils


// MARK: EndpointDecodingStrategy

public protocol EndpointDecodingStrategy {
    associatedtype Input = Data
    
    func strategy<Element: Decodable>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, Input>
}


// MARK: DecodingStrategy Conversion

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
            fatalError("Couldn't find matching 'EndpointParameter' with id \(parameter.id) while determining 'DecodingStrategy'.")
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


// MARK: AnyEndpointDecodingStrategy

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


// MARK: TransformingStrategy

public struct TransformingEndpointStrategy<S: EndpointDecodingStrategy, I>: EndpointDecodingStrategy {
    private let transformer: (I) throws -> S.Input
    private let strategy: S
    
    public init(_ strategy: S, using transformer: @escaping (I) throws -> S.Input) {
        self.strategy = strategy
        self.transformer = transformer
    }
    
    public func strategy<Element>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, I> where Element : Decodable, Element : Encodable {
        TransformingParameterStrategy(strategy.strategy(for: parameter), using: transformer).typeErased
    }
}

public extension EndpointDecodingStrategy {
    func transformed<I>(_ transformer: @escaping (I) throws -> Self.Input) -> TransformingEndpointStrategy<Self, I> {
        TransformingEndpointStrategy(self, using: transformer)
    }
}


// MARK: Implementations

public struct NumberOfContentParameterDependentStrategy<Input>: EndpointDecodingStrategy {
    private let strategy: AnyEndpointDecodingStrategy<Input>
    
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
    
    
    public func strategy<Element>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, Input> where Element : Decodable, Element : Encodable {
        strategy.strategy(for: parameter)
    }
}

public extension NumberOfContentParameterDependentStrategy where Input == Data {
    static func oneIdentityOrAllNamedContentStrategy(_ decoder: AnyDecoder, for endpoint: AnyEndpoint) -> Self {
        self.init(for: endpoint, using: AllIdentityStrategy(decoder), or: AllNamedStrategy(decoder))
    }
}

public struct AllNamedStrategy: EndpointDecodingStrategy {
    private let decoder: AnyDecoder
    
    public init(_ decoder: AnyDecoder) {
        self.decoder = decoder
    }
    
    public func strategy<Element>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, Data> where Element : Decodable, Element : Encodable {
        NamedChildPatternStrategy<DynamicNamePattern<IdentityPattern<Element>>>(parameter.name, decoder).typeErased
    }
}


public struct ParameterTypeSpecific<P: EndpointDecodingStrategy, B: EndpointDecodingStrategy>: EndpointDecodingStrategy where P.Input == B.Input {
    private let backup: B
    private let primary: P
    private let parameterType: ParameterType
    
    public init(_ type: ParameterType = .content, using primary: P, otherwise backup: B) {
        self.backup = backup
        self.primary = primary
        self.parameterType = type
    }
    
    public func strategy<Element>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, P.Input> where Element : Decodable, Element : Encodable {
        if parameter.parameterType == self.parameterType {
            return primary.strategy(for: parameter)
        } else {
            return backup.strategy(for: parameter)
        }
    }
}


public struct InterfaceExporterLegacyStrategy<IE: LegacyInterfaceExporter>: EndpointDecodingStrategy {
    private let exporter: IE
    
    public init(_ exporter: IE) {
        self.exporter = exporter
    }
    
    public func strategy<Element>(for parameter: EndpointParameter<Element>) -> AnyParameterDecodingStrategy<Element, IE.ExporterRequest> where Element : Decodable, Element : Encodable {
        InterfaceExporterLegacyParameterStrategy<IE, Element>(parameter: parameter, exporter: exporter).typeErased
    }
}


private struct InterfaceExporterLegacyParameterStrategy<IE: LegacyInterfaceExporter, E: Codable>: ParameterDecodingStrategy {
    let parameter: EndpointParameter<E>
    let exporter: IE
    
    func decode(from input: IE.ExporterRequest) throws -> E {
        let result = try exporter.retrieveParameter(parameter, for: input)
        
        switch result {
        case let .some(.some(value)):
            return value
        case .some(.none):
            throw DecodingError.valueNotFound(E.self, DecodingError.Context(
                codingPath: [],
                debugDescription: "Exporter \(IE.self) encountered an explicit 'nil' value for \(parameter) in \(input).",
                underlyingError: nil))
        case .none:
            throw DecodingError.keyNotFound(parameter.name, DecodingError.Context(
                codingPath: [],
                debugDescription: "Exporter \(IE.self) could not decode a value for \(parameter) from \(input).",
                underlyingError: nil))
        }
    }
}
