//
//  Input.swift
//  
//
//  Created by Max Obermeier on 04.12.20.
//

import Foundation
@_implementationOnly import AssociatedTypeRequirementsVisitor

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

public enum ParameterUpdateResult {
    case ok
    case error(ParameterUpdateError)
}

public enum InputCheckResult {
    case ok
    case missing([String])
}

public protocol Input {
    
    mutating func update(_ parameter: String, with value: Any) -> ParameterUpdateResult
    
    mutating func check() -> InputCheckResult
    
    mutating func apply()
}

public enum ParameterCheckResult {
    case ok
    case missing
}

public protocol InputParameter {
    
    mutating func update(_ value: Any) -> ParameterUpdateResult
    
    nonmutating func check() -> ParameterCheckResult
    
    mutating func apply()
    
}

public struct AnyInput: Input {
    private(set) public var parameters: [String: Optional<Any>] = [:]
    
    public init() { }
    
    public mutating func update(_ parameter: String, with value: Any) -> ParameterUpdateResult {
        if value is NSNull {
            parameters[parameter] = Optional<Any>.none
        } else {
            parameters[parameter] = value
        }
        return .ok
    }
    
    public mutating func check() -> InputCheckResult {
        return .ok
    }
    
    public mutating func apply() { }
}

public struct SomeInput: Input {
    
    private(set) public var parameters: [String: InputParameter]
    
    public init(parameters: [String: InputParameter]) {
        self.parameters = parameters
    }
    
    
    public mutating func update(_ parameter: String, with value: Any) -> ParameterUpdateResult {
        guard var p = parameters[parameter] else {
            return .error(.notExistant)
        }
        
        let result = p.update(value)
        parameters[parameter] = p
        return result
    }
    
    public func check() -> InputCheckResult {
        return self.parameters.map{ (name, parameter) -> InputCheckResult in
            switch parameter.check() {
            case .ok:
                return .ok
            case .missing:
                return .missing([name])
            }
        }.reduce(.ok, { (a, c) in
            switch a {
            case .ok:
                return c
            case .missing(let parameters):
                switch c {
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

public struct Parameter<Type>: InputParameter {
    
    private var _interim: Type??
    private(set) public var value: Type??
    
    public init() { }
    
    public mutating func update(_ value: Any) -> ParameterUpdateResult {
        if let newValue = value as? Type {
            self._interim = newValue
        } else if value is NSNull {
            self._interim = .some(nil)
        } else {
            return .error(.badType)
        }
        return .ok
    }
    
    public nonmutating func check() -> ParameterCheckResult {
        return .ok
    }
    
    public mutating func apply() {
        self.value = _interim
    }
}
