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
    
    func check() -> InputCheckResult
}

public enum ParameterCheckResult {
    case ok
    case missing
}

public protocol InputParameter {
    
    mutating func update(_ value: Any) -> ParameterUpdateResult
    nonmutating func check() -> ParameterCheckResult
    
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
    
    
}


public enum Mutability {
    case constant
    case variable
}

public enum Necessity<T> {
    case required
    case optional
    case `default`(T)
}

public struct Parameter<T>: InputParameter {
    
    private let mutability: Mutability
    private let necessity: Necessity<T>
    
    private var _value: T?
    
    public var value: T? {
        if let v = _value {
            return v
        }
        switch self.necessity {
        case .default(let v):
            return v
        default:
            return nil
        }
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
        
        if self._value == nil {
            self._value = v
            return .ok
        } else {
            switch self.mutability {
            case .variable:
                self._value = v
                return .ok
            case .constant:
                return .error(.notMutable)
            }
        }
    }
    
    public nonmutating func check() -> ParameterCheckResult {
        if self._value == nil {
            switch self.necessity {
            case .default(_), .optional:
                return .ok
            case .required:
                return .missing
            }
        } else {
            return .ok
        }
    }
    
}
