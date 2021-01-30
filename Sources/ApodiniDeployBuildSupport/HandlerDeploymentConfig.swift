//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-30.
//

import Foundation


open class AnyDeploymentOptionKey {
    public let key: String
    
    public init(key: String) {
        self.key = "\(Self.self).\(key)"
    }
}



open class DeploymentOptionKey<Value: Codable>: AnyDeploymentOptionKey {
    public typealias Value = Value
    
    public let defaultValue: Value
    
    public init<T>(key: String) where Value == Optional<T> { // allow default-value-less initialization if nil is a valid value
        self.defaultValue = nil
        super.init(key: key)
    }
    
    public init(defaultValue: Value, key: String) {
        self.defaultValue = defaultValue
        super.init(key: key)
    }
}



public class CollectedHandlerConfigOption: Codable, CustomStringConvertible {
    private enum ValueStorage {
        case encoded(Data)
        case unencoded(value: Any, encodingFn: () throws -> Data)
    }
    
    enum CodingKeys: String, CodingKey {
        case key
        case encodedValue
    }
    
    
    let key: String
    private var valueStorage: ValueStorage
    
    
    public init<Value>(key: DeploymentOptionKey<Value>, value: Value) {
        self.key = key.key
        self.valueStorage = .unencoded(value: value, encodingFn: { try JSONEncoder().encode(value) })
    }
    
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.key = try container.decode(String.self, forKey: .key)
        self.valueStorage = .encoded(try container.decode(Data.self, forKey: .encodedValue))
    }
    
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        switch valueStorage {
        case .encoded(let data):
            try container.encode(data, forKey: .encodedValue)
        case .unencoded(value: _, let encodingFn):
            try container.encode(try encodingFn(), forKey: .encodedValue)
        }
    }
    
    
    public var description: String {
        var desc = ""
        desc += "\(Self.self)(key: \(key)"
        switch valueStorage {
        case .encoded(let data):
            desc += ", value: \(data)"
        case .unencoded(let value, encodingFn: _):
            desc += ", value: \(value)"
        }
        desc += ")"
        return desc
    }
    
    
    public func readValue<Value: Codable>(as _: Value.Type) throws -> Value {
        switch valueStorage {
        case .unencoded(let value, encodingFn: _):
            if let typedValue = value as? Value {
                return typedValue
            } else {
                throw ApodiniDeploySupportError(message: "Unable to read value as '\(Value.self)'. (Actual type: '\(type(of: value))'.)")
            }
        case .encoded(let data):
            // The idea here is to "cache" the result of the decode operation,
            // by changing the value storage to an "unencoded" state (which just happens to contain the already-encoded value)
            let value = try JSONDecoder().decode(Value.self, from: data)
            self.valueStorage = ValueStorage.unencoded(value: value, encodingFn: { data })
            return value
        }
    }
}





