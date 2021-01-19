import Foundation
import Fluent

enum TypeContainer: Codable, Equatable {
    case string(String)
    case bool(Bool)
    case int(Int)
    case int8(Int8)
    case int16(Int16)
    case int32(Int32)
    case int64(Int64)
    case uint(UInt)
    case uint8(UInt8)
    case uint16(UInt16)
    case uint32(UInt32)
    case uint64(UInt64)
    case uuid(UUID)
    case float(Float)
    case double(Double)
    case noValue
    
    // swiftlint:disable cyclomatic_complexity
    init(from decoder: Decoder) throws {
        let values = try decoder.singleValueContainer()
        self = .noValue
        if let value = try? values.decode(Int.self) {
            self = .int(value)
        } else if let value = try? values.decode(Int8.self) {
            self = .int8(value)
        } else if let value = try? values.decode(Int16.self) {
            self = .int16(value)
        } else if let value = try? values.decode(Int32.self) {
            self = .int32(value)
        } else if let value = try? values.decode(Int64.self) {
            self = .int64(value)
        } else if let value = try? values.decode(UInt.self) {
            self = .uint(value)
        } else if let value = try? values.decode(UInt8.self) {
            self = .uint8(value)
        } else if let value = try? values.decode(UInt16.self) {
            self = .uint16(value)
        } else if let value = try? values.decode(UInt32.self) {
            self = .uint32(value)
        } else if let value = try? values.decode(UInt64.self) {
            self = .uint64(value)
        } else if let value = try? values.decode(Double.self) {
            self = .double(value)
        } else if let value = try? values.decode(Float.self) {
            self = .float(value)
        } else if let value = try? values.decode(UUID.self) {
            self = .uuid(value)
        } else if let value = try? values.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? values.decode(String.self) {
            self = .string(value)
        }
    }
    
    // swiftlint:disable cyclomatic_complexity
    init(with codable: Codable?) {
        guard let wrappedValue = codable else {
            self = .noValue
            return
        }
        if let value = wrappedValue as? Int {
            self = .int(value)
        } else if let value = wrappedValue as? Int8 {
            self = .int8(value)
        } else if let value = wrappedValue as? Int16 {
            self = .int16(value)
        } else if let value = wrappedValue as? Int32 {
            self = .int32(value)
        } else if let value = wrappedValue as? Int64 {
            self = .int64(value)
        } else if let value = wrappedValue as? UInt {
            self = .uint(value)
        } else if let value = wrappedValue as? UInt8 {
            self = .uint8(value)
        } else if let value = wrappedValue as? UInt16 {
            self = .uint16(value)
        } else if let value = wrappedValue as? UInt32 {
            self = .uint32(value)
        } else if let value = wrappedValue as? UInt64 {
            self = .uint64(value)
        } else if let value = wrappedValue as? Double {
            self = .double(value)
        } else if let value = wrappedValue as? Float {
            self = .float(value)
        } else if let value = wrappedValue as? UUID {
            self = .uuid(value)
        } else if let value = wrappedValue as? Bool {
            self = .bool(value)
        } else if let value = wrappedValue as? String {
            self = .string(value)
        } else {
            self = .noValue
        }
    }
    
    // swiftlint:disable cyclomatic_complexity
    func typed() -> Codable? {
        switch self {
        case .bool(let value):
            return value
        case .string(let value):
            return value
        case .int(let value):
            return value
        case .int8(let value):
            return value
        case .int16(let value):
            return value
        case .int32(let value):
            return value
        case .int64(let value):
            return value
        case .uint(let value):
            return value
        case .uint8(let value):
            return value
        case .uint16(let value):
            return value
        case .uint32(let value):
            return value
        case .uint64(let value):
            return value
        case .uuid(let value):
            return value
        case .float(let value):
            return value
        case .double(let value):
            return value
        case .noValue:
            return nil
        }
    }
    
    // swiftlint:disable cyclomatic_complexity
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .int8(let value):
            try container.encode(value)
        case .int16(let value):
            try container.encode(value)
        case .int32(let value):
            try container.encode(value)
        case .int64(let value):
            try container.encode(value)
        case .uint(let value):
            try container.encode(value)
        case .uint8(let value):
            try container.encode(value)
        case .uint16(let value):
            try container.encode(value)
        case .uint32(let value):
            try container.encode(value)
        case .uint64(let value):
            try container.encode(value)
        case .uuid(let value):
            try container.encode(value)
        case .float(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .noValue:
            break
        }
    }

    var description: String {
        self.typed().debugDescription
    }
}

extension TypeContainer: LosslessStringConvertible {
    public init?(_ description: String) {
        // As query parameters are currently internally used a `.lightweight` and therefore not initialized using this init,
        // there is currently no mapping for this and will always be defaulted to `.noValue`.Will be added in the future.
        fatalError("This .init should never be called as there is currently no type mapping implemented")
    }
}
