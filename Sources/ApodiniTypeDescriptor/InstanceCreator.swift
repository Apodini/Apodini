import Foundation
@_implementationOnly import Runtime

enum InstanceCreatorError: Swift.Error {
    case nonSupportedDictionaryKey(Any.Type)
    case failedCastingInstanceToEncodable
}

/// Creates an instance out of a type
/// Relies on `createInstance` API of Runtime
private struct InstanceCreator {
    
    /// Instance that has been created
    var instance: Any
    
    init(type: Any.Type) throws {
        let typeInfo = try Runtime.typeInfo(of: type)
        let genericTypes = typeInfo.genericTypes
        let mangledName = MangledName(type)
        
        /**
         `createInstance` initializes arrays and dictionaries as empty, and optionals as nil,
         Therefore we ensure to create one single instance for an array, a dictionary
         and the wrapped value of an optional
         */
        if mangledName == .array, let elementType = genericTypes.first {
            instance = [try InstanceCreator(type: elementType).instance]
        } else if mangledName == .dictionary,
                  let keyType = genericTypes.first,
                  let valueType = genericTypes.last {
            guard let primitiveType = PrimitiveType(keyType) else {
                throw InstanceCreatorError.nonSupportedDictionaryKey(keyType)
            }
            instance = try InstanceCreator.dictionaryInstance(key: primitiveType, valueType: valueType)
        } else if mangledName == .optional,
                  let wrappedValueType = genericTypes.first {
            instance = try InstanceCreator(type: wrappedValueType).instance
        } else {
            instance = try createInstance(of: type)
            try handleEmptyProperties()
        }
    }
    
    mutating func handleEmptyProperties() throws {
        let typeInfo = try Runtime.typeInfo(of: type(of: instance))
        
        try typeInfo.properties
            .filter { $0.type is Encodable.Type }
            .forEach { property in
                try handleOptional(for: property)
                try handleDictionary(for: property)
                try handleArray(for: property)
            }
    }
    
    mutating func handleOptional(for property: PropertyInfo) throws {
        guard
            MangledName(property.type) == .optional,
            let wrappedValueType = try? Runtime.typeInfo(of: property.type).genericTypes.first
        else { return }
        
        try property.set(value: try InstanceCreator(type: wrappedValueType).instance, on: &instance)
    }
    
    mutating func handleDictionary(for property: PropertyInfo) throws {
        guard MangledName(property.type) == .dictionary else {
            return
        }
        
        let genericTypes = try Runtime.typeInfo(of: property.type).genericTypes
        guard
            let keyType = genericTypes.first,
            let valueType = genericTypes.last
        else { return }
        
        guard let primitiveType = PrimitiveType(keyType) else {
            throw InstanceCreatorError.nonSupportedDictionaryKey(keyType)
        }
        
        let propertyInstance = try InstanceCreator.dictionaryInstance(key: primitiveType, valueType: valueType)
        try property.set(value: propertyInstance, on: &instance)
    }
    
    mutating func handleArray(for property: PropertyInfo) throws {
        guard
            MangledName(property.type) == .array,
            let elementType = try? Runtime.typeInfo(of: property.type).genericTypes.first
        else { return }
        
        try property.set(value: [try InstanceCreator(type: elementType).instance], on: &instance)
    }
    
    func typedInstance<T: Encodable>(_ type: T.Type) throws -> T {
        guard let instance = instance as? T else {
            throw InstanceCreatorError.failedCastingInstanceToEncodable
        }
        return instance
    }
}

extension InstanceCreator {
    static func dictionaryInstance(key: PrimitiveType, valueType: Any.Type) throws -> Any {
        let valueInstance = try InstanceCreator(type: valueType).instance
        switch key {
        case .int: return [Int(): valueInstance]
        case .int32: return [Int32(): valueInstance]
        case .int64: return [Int64(): valueInstance]
        case .uint: return [UInt(): valueInstance]
        case .uint32: return [UInt32(): valueInstance]
        case .uint64: return [UInt64(): valueInstance]
        case .bool: return [true: valueInstance]
        case .string: return [String(): valueInstance]
        case .double: return [Double(): valueInstance]
        case .float: return [Float(): valueInstance]
        case .uuid: return [UUID(): valueInstance]
        }
    }
}

func instance<T: Encodable>(_ type: T.Type) throws -> T {
    try InstanceCreator(type: type).typedInstance(T.self)
}
