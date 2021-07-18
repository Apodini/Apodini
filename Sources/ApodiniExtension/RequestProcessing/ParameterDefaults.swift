//
//  ParameterDefaults.swift
//  
//
//  Created by Max Obermeier on 06.07.21.
//

import Foundation
import Apodini

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

public extension AsyncSequence where Element: Request {
    /// Wraps each incoming `Request` into a ``DefaultValueStore/DefaultInsertingRequest`` using
    /// the given `defaults`.
    func insertDefaults(with defaults: DefaultValueStore) -> AsyncMapSequence<Self, DefaultValueStore.DefaultInsertingRequest> {
        self.map { request in
            defaults.insertDefaults(request)
        }
    }
}

public extension Request {
    /// Wraps this `Request` into a ``DefaultValueStore/DefaultInsertingRequest`` using
    /// the given `defaults`.
    func insertDefaults(with defaults: DefaultValueStore) -> DefaultValueStore.DefaultInsertingRequest {
        defaults.insertDefaults(self)
    }
}
