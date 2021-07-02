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
    /// This `Publisher` maps each incoming `Request` into a ``CachingRequest``.
    func cache() -> OpenCombine.Publishers.Map<Self, CachingRequest> {
        self.map { request in
            request.cache()
        }
    }
}

public extension Request {
    /// Wraps this `Request` into a ``CachingRequest``.
    func cache() -> CachingRequest {
        CachingRequest(self)
    }
}

/// A wrapper around an Apodini `Request` which caches all of the original request's
/// properties as well as the results of the ``retrieveParameter(_:)`` function.
public class CachingRequest: WithRequest {
    public var request: Request
    
    private var cache = [UUID: Any]()
    
    init(_ request: Request) {
        self.request = request
    }
    
    public lazy var description: String = request.description

    public lazy var debugDescription: String = request.debugDescription

    public lazy var eventLoop: EventLoop = request.eventLoop

    public lazy var remoteAddress: SocketAddress? = request.remoteAddress
    
    public lazy var information: Set<AnyInformation> = request.information
    
    public func retrieveParameter<Element>(_ parameter: Parameter<Element>) throws -> Element where Element: Decodable, Element: Encodable {
        if let cached = cache[parameter.id] {
            if let typed = cached as? Element {
                return typed
            }
        }
        
        let value = try request.retrieveParameter(parameter)
        cache[parameter.id] = value
        return value
    }
    
    /// This function allows for accessing the values stored in the cache.
    ///
    /// When ``peak(_:)`` is called it will never request a value from the
    /// underlying `Request`, instead it solely queries its cache and returns
    /// any value stored there.
    public func peak(_ parameter: UUID) -> Any? {
        cache[parameter]
    }
}


// MARK: Default Value Insertion

/// This value stores the default values for each `Parameter` of an endpoint. It can
/// be used to obtain an ``DefaultInsertingRequest`` using the `Request`'s
/// `insertDefaults(with:)` function.
///
/// - Note: An instance can be obtained from any local `Blackboard`, e.g. an `Endpoint`.
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
    
    /// A `Request` which completes another `Request` by inserting
    /// default values where possible if the wrapped `Request`'s
    /// `retrieveParameter(_:)` function fails.
    ///
    /// - Note: Usually, any request should be wrapped in a ``DefaultInsertingRequest``.
    public struct DefaultInsertingRequest: WithRequest {
        public var request: Request {
            _request
        }
        
        private var _request: Request
        
        private let handler: (UUID, Error) throws -> Any
        
        init(request: Request, handler: @escaping (UUID, Error) throws -> Any) {
            self._request = request
            self.handler = handler
        }

        public func retrieveParameter<Element>(_ parameter: Parameter<Element>) throws -> Element where Element: Decodable, Element: Encodable {
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

private protocol DefaultNilValueProvider {
    var nilValue: Any? { get }
}

extension EndpointParameter: DefaultNilValueProvider {
    var nilValue: Any? {
        if nilIsValidValue {
            return .some(Type?.none as Any)
        } else {
            return .none
        }
    }
}

public extension Publisher where Output: Request {
    /// Wrapps each incoming `Request` into a ``DefaultValueStore/DefaultInsertingRequest`` using
    /// the given `defaults`.
    func insertDefaults(with defaults: DefaultValueStore) -> OpenCombine.Publishers.Map<Self, DefaultValueStore.DefaultInsertingRequest> {
        self.map { request in
            defaults.insertDefaults(request)
        }
    }
}

public extension Request {
    /// Wrapps this `Request` into a ``DefaultValueStore/DefaultInsertingRequest`` using
    /// the given `defaults`.
    func insertDefaults(with defaults: DefaultValueStore) -> DefaultValueStore.DefaultInsertingRequest {
        defaults.insertDefaults(self)
    }
}


// MARK: Mutability Validation

public extension Publisher where Output: Request {
    /// Wrapps all incoming `Request`s in ``MutabilityValidatingRequest``s, which share
    /// a common storage for providing stateful validation.
    func validateParameterMutability() -> OpenCombine.Publishers.Map<Self, MutabilityValidatingRequest<Output>> {
        self.reduce()
    }
}


/// A `Request` which wrapps another `Request` and forwards its properties but performs
/// a statful validation of the Apodini `Mutability` of the requested parameters before forwarding
/// the results of `retrieveParameter(_:)`.
///
/// This wrapper should be used on any endpoint that handles a sequence of `Request`s, i.e. more
/// than one. It validates that a `.mutability(.constant))` `Parameter`'s value does not
/// change once observed once.
///
/// - Note: Must be used last in a sequence of failable `Request`s, otherwise the internal
/// state might get corrupted.
public struct MutabilityValidatingRequest<R: Request>: WithRequest, Initializable {
    public typealias InitialInput = R
    
    public var request: Request {
        _request as Request
    }
    
    private var _request: R
    
    private var persistentStore: Box<(previousValues: [UUID: (backup: Any?, last: Any?)], failed: Bool)>
    
    public init(_ initial: R) {
        self._request = initial
        self.persistentStore = Box((previousValues: [UUID: (backup: Any?, last: Any?)](), failed: false))
    }
    
    internal init(request: R, persistentStore: Box<(previousValues: [UUID: (backup: Any?, last: Any?)], failed: Bool)>) {
        self._request = request
        self.persistentStore = persistentStore
    }
    
    public func retrieveParameter<Element>(_ parameter: Parameter<Element>) throws -> Element where Element: Decodable, Element: Encodable {
        do {
            let retrievedValue = try _request.retrieveParameter(parameter)
            
            switch _Internal.option(for: .mutability, on: parameter) ?? .variable {
            case .constant:
                if case let .some((_, .some(initialValue))) = self.persistentStore.value.previousValues[parameter.id] {
                    if !AnyEquatable.compare(initialValue as Any, retrievedValue as Any).isEqual {
                        throw ApodiniError(type: .badInput, reason: "Parameter retrieval returned value for constant '\(parameter)' even though its value has already been defined.")
                    }
                } else {
                    self.persistentStore.value.previousValues[parameter.id] = (nil, retrievedValue)
                }
            case .variable:
                break
            }
            
            return retrievedValue
        } catch {
            self.persistentStore.value.failed = true
            throw error
        }
    }
}

extension MutabilityValidatingRequest: Reducible {
    public typealias Input = R
    
    public func reduce(with new: R) -> Self {
        for (key, (backup, last)) in self.persistentStore.value.previousValues {
            self.persistentStore.value.previousValues[key] = self.persistentStore.value.failed ? (backup, backup) : (last, last)
        }
        self.persistentStore.value.failed = false
        return MutabilityValidatingRequest(request: new, persistentStore: persistentStore)
    }
}
