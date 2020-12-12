//
//  Input.swift
//  
//
//  Created by Max Obermeier on 04.12.20.
//

public enum ParameterUpdateError {
    case notMutable, badType, notExistant
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


public enum Mutability {
    case constant
    case variable
}

public enum Necessity<T> {
    case required
    case optional
}

public struct Parameter<T>: InputParameter {
    
    private let mutability: Mutability
    private let necessity: Necessity<T>
    
    private var _interim: T?
    private var _value: T?
    
    public var value: T? {
        if let v = _value {
            return v
        }
        return nil
    }
    
    public init(mutability: Mutability, necessity: Necessity<T>) {
        self.mutability = mutability
        self.necessity = necessity
        self._value = nil
    }
    
    public mutating func update(_ value: Any) -> ParameterUpdateResult {
        guard let v = value as? T else {
            return .error(.badType)
        }
        
        if self._interim == nil {
            self._interim = v
            return .ok
        } else {
            switch self.mutability {
            case .variable:
                self._interim = v
                return .ok
            case .constant:
                // TODO: check if new value is same as _value
                return .error(.notMutable)
            }
        }
    }
    
    public nonmutating func check() -> ParameterCheckResult {
        if self._interim == nil {
            switch self.necessity {
            case .optional:
                return .ok
            case .required:
                return .missing
            }
        } else {
            return .ok
        }
    }
    
    public mutating func apply() {
        self._value = _interim
    }
    
}
