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

public protocol ParameterDecoder {
    func decode<T: Decodable>(_: T.Type) throws -> T??
}

public protocol Input {
    
    mutating func update(_ parameter: String, using decoder: ParameterDecoder) -> ParameterUpdateResult
    
    mutating func check() -> InputCheckResult
    
    mutating func apply()
}

public enum ParameterCheckResult {
    case ok
    case missing
}

public protocol InputParameter {
    
    mutating func update(using decoder: ParameterDecoder) -> ParameterUpdateResult
    
    nonmutating func check() -> ParameterCheckResult
    
    mutating func apply()
    
}

public struct SomeInput: Input {
    
    private(set) public var parameters: [String: InputParameter]
    
    public init(parameters: [String: InputParameter]) {
        self.parameters = parameters
    }
    
    
    public mutating func update(_ parameter: String, using decoder: ParameterDecoder) -> ParameterUpdateResult {
        guard var p = parameters[parameter] else {
            return .error(.notExistant)
        }
        
        let result = p.update(using: decoder)
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

public struct Parameter<Type: Decodable>: InputParameter {
    
    private var _interim: Type??
    private(set) public var value: Type??
    
    public init() { }
    
    public mutating func update(using decoder: ParameterDecoder) -> ParameterUpdateResult {
        do {
            self._interim = try decoder.decode(Type.self)
            return .ok
        } catch {
            print(error)
            return .error(.badType)
        }
    }
    
    public nonmutating func check() -> ParameterCheckResult {
        return .ok
    }
    
    public mutating func apply() {
        self.value = _interim
    }
}
