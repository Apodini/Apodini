//
//  Input.swift
//  
//
//  Created by Max Obermeier on 04.12.20.
//

import Foundation

/// A `ParameterDecoder` allows for decoding an element of given type `T`.
public protocol ParameterDecoder {
    /// Try do decode an element of type `T` from the internal data.
    /// - Returns:
    ///     - `nil` if the `ParameterDecoder` does not hold any relevant information
    ///     - `.some(nil)` if the `ParameterDecoder` found `null` at the relevant place
    ///     - `.some(.some(T))` if the `ParameterDecoder` found an object of type `T` at the relevant place
    ///
    func decode<T: Decodable>(_: T.Type) throws -> T??
}

/// A stateful abstraction for representing validatable input.
public protocol Input {
    /// Update the value for the given `parameter` using the given `decoder` and validate this new value.
    mutating func update(_ parameter: String, using decoder: ParameterDecoder) -> ParameterUpdateResult
    /// Check the complete `Input` for validity after all parameters have been updated.
    nonmutating func check() -> InputCheckResult
    /// Expose the latest updates to its upstream users. E.g. update public variables.
    mutating func apply()
}

/// A stateful abstraction for representing a single validatable parameter.
public protocol InputParameter {
    /// Update the internal value using the given `decoder` and validate this new value.
    mutating func update(using decoder: ParameterDecoder) -> ParameterUpdateResult
    /// Check the parameter` for validity.
    nonmutating func check() -> ParameterCheckResult
    /// Expose the latest updates to its upstream users. E.g. update public variables.
    mutating func apply()
}


/// A default error type that covers most cases relevant when validating
/// input parameters.
public enum ParameterUpdateError: WSError {
    case notMutable, badType, notExistant
    
    public var reason: String {
        switch self {
        case .notMutable:
            return "is a constant"
        case .badType:
            return "is of wrong type"
        case .notExistant:
            return "does not exist on this endpoint"
        }
    }
}

/// Possible return types for updating a parameter.
public enum ParameterUpdateResult {
    /// The parameter could be decoded from the given
    /// decoder and is valid.
    case ok
    /// The parameter could not be decoded or it is invalid.
    case error(ParameterUpdateError)
}

/// Possible return types for checking a parameters
/// presence.
public enum ParameterCheckResult {
    /// The parameter either is present or it doesn't have
    /// to be.
    case ok
    /// The parameter is not present even though it sould.
    case missing
}

/// Possible return types for checking the presence of all
/// parameters.
public enum InputCheckResult {
    /// All required parameters are present.
    case ok
    /// The listed parameters are missing even though they shouldn't.
    case missing([String])
}


/// An implementation of `Input` that accumulates results from given `InputParameter`s.
public struct SomeInput: Input {
    public private(set) var parameters: [String: InputParameter]
    
    public init(parameters: [String: InputParameter]) {
        self.parameters = parameters
    }
    
    public mutating func update(_ parameter: String, using decoder: ParameterDecoder) -> ParameterUpdateResult {
        guard var inputParameter = parameters[parameter] else {
            return .error(.notExistant)
        }
        
        let result = inputParameter.update(using: decoder)
        parameters[parameter] = inputParameter
        return result
    }
    
    public func check() -> InputCheckResult {
        self.parameters.map { name, parameter -> InputCheckResult in
            switch parameter.check() {
            case .ok:
                return .ok
            case .missing:
                return .missing([name])
            }
        }
        .reduce(.ok, { accumulator, current in
            switch accumulator {
            case .ok:
                return current
            case .missing(let parameters):
                switch current {
                case .ok:
                    return .missing(parameters)
                case .missing(let newParameters):
                    return .missing(parameters + newParameters)
                }
            }
        })
    }
    
    public mutating func apply() {
        for (id, _) in self.parameters {
            self.parameters[id]?.apply()
        }
    }
}

/// An implementation of `InputParameter` that only asserts type, but not necessity,
/// mutability or optionality and has no state.
public struct BasicInputParameter<Type: Decodable>: InputParameter {
    private var _interim: Type??
    /// The current value set for this `Parameter`. It is:
    ///     - `nil` if no value was set
    ///     - `.some(nil)` if an explicit `null` value was set
    ///     - `.some(.some(T))` if an object of type `T` was set
    public private(set) var value: Type??
    
    public init() { }
    
    public mutating func update(using decoder: ParameterDecoder) -> ParameterUpdateResult {
        do {
            self._interim = try decoder.decode(Type.self)
            return .ok
        } catch {
            return .error(.badType)
        }
    }
    
    public nonmutating func check() -> ParameterCheckResult {
        .ok
    }
    
    public mutating func apply() {
        self.value = _interim
        self._interim = nil
    }
}
