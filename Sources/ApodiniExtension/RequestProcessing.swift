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
    func cache() -> OpenCombine.Publishers.Map<Self, CachingRequest> {
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
    
    private let handler: (UUID, Error) throws -> Any
    
    
    internal init(_ parameters: EndpointParameters) {
        let defaultValues = parameters.reduce(into: [UUID: () -> Any](), { storage, parameter in
            if let defaultValue = parameter.typeErasuredDefaultValue, parameter.necessity == .optional {
                storage[parameter.id] = defaultValue
            }
        })
        
        let defaultNilValues = parameters.reduce(into: [UUID: Any](), { storage, parameter in
            if case let .some(.some(nilValue)) = (parameter as? DefaultNilValueProvider)?.nilValue {
                storage[parameter.id] = nilValue
            }
        })
        
        let descriptions = parameters.reduce(into: [UUID: String](), { storage, parameter in
            storage[parameter.id] = parameter.description
        })
        
        handler = { uuid, originalError in
            if let defaultValue = defaultValues[uuid] {
                return defaultValue()
            }
            if let defaultNilValue = defaultNilValues[uuid] {
                return defaultNilValue
            }
            throw ApodiniError(type: .badInput, reason: "Didn't retrieve any parameters for a required parameter '\(descriptions[uuid] ?? "??")'.", description: "\(originalError)")
        }
    }
    
    func insertDefaults(_ request: Request) -> DefaultInsertingRequest {
        DefaultInsertingRequest(request: request, handler: handler)
    }
    
    public struct DefaultInsertingRequest {
        var _request: Request
        
        let handler: (UUID, Error) throws -> Any
        
        init(request: Request, handler: @escaping (UUID, Error) throws -> Any) {
            self._request = request
            self.handler = handler
        }

        public func retrieveParameter<Element>(_ parameter: Parameter<Element>) throws -> Element where Element : Decodable, Element : Encodable {
            do {
                return try _request.retrieveParameter(parameter)
            } catch {
                guard let typedValue = try handler(parameter.id, error) as? Element else {
                    fatalError("Internal logic of DefaultValueStore broken: type mismatch")
                }
                return typedValue
            }
        }
    }
}

extension DefaultValueStore.DefaultInsertingRequest: WithRequest {
    public var request: Request {
        _request
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
    func insertDefaults(with defaults: DefaultValueStore) -> OpenCombine.Publishers.Map<Self, DefaultValueStore.DefaultInsertingRequest> {
        self.map { request in
            defaults.insertDefaults(request)
        }
    }
}

public extension Request {
    func insertDefaults(with defaults: DefaultValueStore) -> DefaultValueStore.DefaultInsertingRequest {
        defaults.insertDefaults(self)
    }
}



// MARK: Mutability Validation

public extension Publisher where Output: Request {
    func validateParameterMutability() -> OpenCombine.Publishers.Map<Self, MutabilityValidatingRequest<Output>>  {
        self.reduce()
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
            
            switch _Internal.option(for: .mutability, on: parameter) ?? .variable {
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
        self._request = new
        return self
    }
}
