//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-30.
//

import Foundation



/// A collection of handler deployment options.
/// The same option may defined multiple times, in which case latter-defined options take precedence.
public struct HandlerDeploymentOptions: Codable {
    public let collectedOptions: [CollectedHandlerConfigOption]
    
    public init() {
        self.collectedOptions = []
    }
    
    public init(_ collectedOptions: [CollectedHandlerConfigOption]) {
        self.collectedOptions = collectedOptions
    }
    
    public init(_ collectedOptions: CollectedHandlerConfigOption...) {
        self.collectedOptions = collectedOptions
    }
    
    public func containsEntry<Value>(for optionKey: DeploymentOptionKey<Value>) -> Bool {
        return collectedOptions.contains { $0.key == optionKey.key }
    }
    
    /// - returns: the value specified for this option key, if a matching entry exists. if no matching entry exists, the default value specified in the option key is returned.
    /// - throws: if an entry does exist but there was an erorr reading (ie decoding) it/
    public func getValue<Value>(forOptionKey optionKey: DeploymentOptionKey<Value>) throws -> Value {
        guard let collectedOption = collectedOptions.last(where: { $0.key == optionKey.key }) else {
            return optionKey.defaultValue
        }
        return try collectedOption.readValue(as: Value.self)
    }
    
    
    public enum OptionsMergingPrecedence {
        case lower, higher
    }
    
    /// Returns a new options object containing both the current object's options and the other object's options.
    /// - parameter newOptionsPrecedence: the precedence of the new options, relative to the current options
    public func merging(with otherOptions: HandlerDeploymentOptions, newOptionsPrecedence: OptionsMergingPrecedence) -> HandlerDeploymentOptions {
        switch newOptionsPrecedence {
        case .lower:
            return HandlerDeploymentOptions(otherOptions.collectedOptions + self.collectedOptions)
            //return HandlerDeploymentOptions(self.collectedOptions + otherOptions.collectedOptions)
        case .higher:
            return HandlerDeploymentOptions(self.collectedOptions + otherOptions.collectedOptions)
            //return HandlerDeploymentOptions(otherOptions.collectedOptions + self.collectedOptions)
        }
    }
}






open class DeploymentOptionKey<Value: Codable> {
    public let key: String
    public let defaultValue: Value
    
    public init(defaultValue: Value, key: String) {
        self.defaultValue = defaultValue
        self.key = "\(Self.self).\(key)"
    }
    
    public convenience init<T>(key: String) where Value == T? { // allow default-value-less initialization if nil is a valid value
        self.init(defaultValue: nil, key: key)
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





