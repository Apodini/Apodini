//
//  ParameterMutability.swift
//  
//
//  Created by Max Obermeier on 23.06.21.
//

import Foundation
import OpenCombine
import Apodini
import ApodiniUtils

public extension AsyncSequence where Element: Request {
    func validateParameterMutability() -> AsyncMapSequence<Self, MutabilityValidatingRequest<Element>> {
        self.reduce()
    }
}

public extension Publisher where Output: Request {
    /// Wraps all incoming `Request`s in ``MutabilityValidatingRequest``s, which share
    /// a common storage for providing stateful validation.
    func validateParameterMutability() -> OpenCombine.Publishers.Map<Self, MutabilityValidatingRequest<Output>> {
        self.reduce()
    }
}


/// A `Request` which wraps another `Request` and forwards its properties but performs
/// a stateful validation of the Apodini `Mutability` of the requested parameters before forwarding
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
