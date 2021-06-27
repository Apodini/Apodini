//
//  RequestProcessing.swift
//  
//
//  Created by Max Obermeier on 23.06.21.
//

import Foundation
import OpenCombine
import Apodini
import ApodiniUtils


// MARK: Caching

public extension Publisher where Output: Request {
    func cache() -> some Publisher {
        self.map { request in
            request.cache()
        }
    }
}

public extension Request {
    func cache() -> CachingRequest {
        CachingRequest(self)
    }
}

public class CachingRequest: WithRequest {
    public var request: Request
    
    private var cache = [UUID: Any]()
    
    init(_ request: Request) {
        self.request = request
    }
    
    lazy public var description: String = request.description

    lazy public var debugDescription: String = request.debugDescription

    lazy public var eventLoop: EventLoop = request.eventLoop

    lazy public var remoteAddress: SocketAddress? = request.remoteAddress
    
    lazy public var information: Set<AnyInformation> = request.information
    
    public func retrieveParameter<Element>(_ parameter: Parameter<Element>) throws -> Element where Element : Decodable, Element : Encodable {
        if let cached = cache[parameter.id] {
            if let typed = cached as? Element {
                return typed
            }
        }
        
        let value = try request.retrieveParameter(parameter)
        cache[parameter.id] = value
        return value
    }
    
    public func peak(_ parameter: UUID) -> Any? {
        cache[parameter]
    }
}


// MARK: Default Value Insertion

public struct DefaultValueStore {
    
    private let handler: (UUID) throws -> Any
    
    
    public init(for endpoint: AnyEndpoint) {
        let defaultValues = endpoint[EndpointParameters.self].reduce(into: [UUID: () -> Any](), { storage, parameter in
            if let defaultValue = parameter.typeErasuredDefaultValue, parameter.necessity == .optional {
                storage[parameter.id] = defaultValue
            }
        })
        
        let defaultNilValues = endpoint[EndpointParameters.self].reduce(into: [UUID: Any](), { storage, parameter in
            if case let .some(.some(nilValue)) = (parameter as? DefaultNilValueProvider)?.nilValue {
                storage[parameter.id] = nilValue
            }
        })
        
        let descriptions = endpoint[EndpointParameters.self].reduce(into: [UUID: String](), { storage, parameter in
            storage[parameter.id] = parameter.description
        })
        
        handler = { uuid in
            if let defaultValue = defaultValues[uuid] {
                return defaultValue()
            }
            if let defaultNilValue = defaultNilValues[uuid] {
                return defaultNilValue
            }
            throw ApodiniError(type: .badInput, reason: "Didn't retrieve any parameters for a required parameter '\(descriptions[uuid] ?? "??")'.")
        }
    }
    
    func insertDefaults(_ request: Request) -> Request {
        DefaultInsertingRequest(request: request, handler: handler)
    }
    
    struct DefaultInsertingRequest: WithRequest {
        private(set) var request: Request
        
        let handler: (UUID) throws -> Any

        func retrieveParameter<Element>(_ parameter: Parameter<Element>) throws -> Element where Element : Decodable, Element : Encodable {
            do {
                return try request.retrieveParameter(parameter)
            } catch DecodingError.keyNotFound(_, _), DecodingError.valueNotFound(_, _) {
                guard let typedValue = try handler(parameter.id) as? Element else {
                    fatalError("Internal logic of DefaultValueStore broken: type mismatch")
                }
                return typedValue
            }
        }
    }
}

private protocol DefaultNilValueProvider {
    var nilValue: Any? { get }
}

extension EndpointParameter: DefaultNilValueProvider {
    var nilValue: Any? {
        if nilIsValidValue {
            return .some(Optional<Type>.none as Any)
        } else {
            return .none
        }
    }
}

public extension Publisher where Output: Request {
    func insertDefaults(with validation: DefaultValueStore) -> some Publisher {
        self.map { request in
            validation.insertDefaults(request)
        }
    }
}

public extension Request {
    func insertDefaults(with validation: DefaultValueStore) -> Request {
        validation.insertDefaults(self)
    }
}



// MARK: Mutability Validation

public extension Publisher where Output: Request {
    func validateParameterMutability() -> some Publisher {
        self.reduce(with: Optional<MutabilityValidatingRequest<Output>>.none)
    }
}

/// - Note: Must be used last in a sequence of failable `Request`s, otherwise the internal
///         state might get corrupted.
public class MutabilityValidatingRequest<R: Request>: WithRequest, Initializable {
    public typealias InitialInput = R
    
    public var request: Request {
        _request as Request
    }
    
    private var _request: R
    
    private var previousValues = [UUID: (backup: Any?, last: Any?)]()
    
    private var failed = false
    
    public required init(_ initial: R) {
        self._request = initial
    }
    
    public func retrieveParameter<Element>(_ parameter: Parameter<Element>) throws -> Element where Element : Decodable, Element : Encodable {
        do {
            let retrievedValue = try _request.retrieveParameter(parameter)
            
            switch IE.option(for: .mutability, on: parameter) ?? .variable {
            case .constant:
                if case let .some((_, .some(initialValue))) = self.previousValues[parameter.id] {
                    if !AnyEquatable.compare(initialValue as Any, retrievedValue as Any).isEqual {
                        throw ApodiniError(type: .badInput, reason: "Parameter retrieval returned value for constant '\(parameter)' even though its value has already been defined.")
                    }
                } else {
                    self.previousValues[parameter.id] = (nil, retrievedValue)
                }
            case .variable:
                break
            }
            
            return retrievedValue
        } catch {
            failed = true
            throw error
        }
    }
}

extension MutabilityValidatingRequest: Reducible {
    public typealias Input = R
    
    public func reduce(with new: R) -> Self {
        for (key, (backup, last)) in previousValues {
            previousValues[key] = failed ? (backup, backup) : (last, last)
        }
        self.failed = false
        self._request = _request
        return self
    }
}
