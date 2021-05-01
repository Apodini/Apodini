import Foundation
@_implementationOnly import Runtime

typealias TypeProperty = (name: String, type: TypeContainer)

enum TypeContainer {
    case bool
    case int
    case int8
    case int16
    case int32
    case int64
    case uint
    case uint8
    case uint16
    case uint32
    case uint64
    case string
    case double
    case float
    case uuid
    case date
    case data
    indirect case array(element: TypeContainer)
    indirect case dictionary(key: TypeContainer, value: TypeContainer)
    indirect case optional(wrappedValue: TypeContainer)
    case `enum`(cases: [String])
    case complex(properties: [TypeProperty])
    
    
    var defaultInitializableType: DefaultInitializable.Type? {
        switch self {
        case .bool: return Bool.self
        case .int: return Int.self
        case .int8: return Int8.self
        case .int16: return Int16.self
        case .int32: return Int32.self
        case .int64: return Int64.self
        case .uint: return UInt.self
        case .uint8: return UInt8.self
        case .uint16: return UInt16.self
        case .uint32: return UInt32.self
        case .uint64: return UInt64.self
        case .string: return String.self
        case .double: return Double.self
        case .float: return Float.self
        case .uuid: return UUID.self
        case .date: return Date.self
        case .data: return Data.self
        default: return nil
        }
    }
    
    var jsonString: String {
        switch self {
        case .array(element: let element):
            return "[\(element.jsonString)]"
        case .dictionary(key: let key, value: let value):
            if key.isString { return "{ \(key.jsonString) : \(value.jsonString) }" }
            return "[\(key.jsonString), \(value.jsonString)]"
        case .optional(wrappedValue: let wrappedValue):
            return "\(wrappedValue.jsonString)"
        case .enum(cases: let cases):
            return cases.first?.asString ?? "{}"
        case .complex(properties: let properties):
            return "{\(properties.map { $0.name.asString + ": \($0.type.jsonString)" }.joined(separator: ", "))}"
        default: return defaultInitializableType?.jsonString ?? "{}"
        }
    }

    
    var isString: Bool {
        if case .string = self { return true }
        return false
    }
    
    init(type: Any.Type) throws {
        let typeInfo = try Runtime.typeInfo(of: type)
        let genericTypes = typeInfo.genericTypes
        let mangledName = MangledName(type)
        if type == Bool.self {
            self = .bool
        } else if type == Int.self {
            self = .int
        } else if type == Int8.self {
            self = .int8
        } else if type == Int16.self {
            self = .int16
        } else if type == Int32.self {
            self = .int32
        } else if type == Int64.self {
            self = .int64
        } else if type == UInt.self {
            self = .uint
        } else if type == UInt32.self {
            self = .uint32
        } else if type == UInt64.self {
            self = .uint64
        } else if type == String.self {
            self = .string
        } else if type == Double.self {
            self = .double
        } else if type == Float.self {
            self = .float
        } else if type == UUID.self {
            self = .uuid
        } else if type == Date.self {
            self = .date
        } else if type == Data.self {
            self = .data
        } else if mangledName == .array, let elementType = genericTypes.first {
            self = .array(element: try .init(type: elementType))
        } else if mangledName == .dictionary, let keyType = genericTypes.first, let valueType = genericTypes.last {
            self = .dictionary(key: try .init(type: keyType), value: try .init(type: valueType))
        } else if mangledName == .optional, let wrappedValueType = genericTypes.first {
            self = .optional(wrappedValue: try .init(type: wrappedValueType))
        } else if typeInfo.kind == .enum {
            self = .enum(cases: typeInfo.cases.map { $0.name })
        } else { self = .complex(properties: try typeInfo.typeProperties()) }
    }
    
    init(value: Any) throws {
        self = try .init(type: type(of: value))
    }
}

extension TypeInfo {
    func typeProperties() throws -> [TypeProperty] {
        var container: [TypeProperty] = []
        try properties.forEach {
            container.append((name: $0.name, type: try .init(type: $0.type)))
        }
        return container
    }
}
