import Foundation
import Fluent
@testable import Apodini

public protocol AnyCodable: Codable {
    
}

//public struct AnyConcreteCodable: AnyCodable {
//    enum DecodeableType {
//        case string, bool, int, int8, int16, int32, int64, uint, uint8, uint16, uint32, uint64, uuid, float, double
//    }
//
//    private var types: [DecodeableType] {
//        [.string, .bool, .int, .int8, .int16, .int32, .int64, .uint, .uint8, .uint16, .uint32, .uint64, .uuid, .float, .double]
//    }
//
//    var wrappedValue: Codable?
//
//    var key: FieldKey?
//
//    init(_ wrappedValue: Codable) {
//        self.wrappedValue = wrappedValue
//    }
//
//    init(_ wrappedValue: Codable, key: FieldKey) {
//        self.wrappedValue = wrappedValue
//        self.key = key
//    }
//
//    public func encode(to encoder: Encoder) throws {
//        try wrappedValue?.encode(to: encoder)
//    }
//
//    public init(from decoder: Decoder) throws {
//        self.init()
//        let values = try decoder.singleValueContainer()
//        for type in types {
//            guard wrappedValue == nil else {
//                return
//            }
//            do {
//                switch type {
//                case .string:
//                    self.wrappedValue = try values.decode(String.self)
//                case .bool:
//                    self.wrappedValue = try values.decode(Bool.self)
//                case .int:
//                    self.wrappedValue = try values.decode(Int.self)
//                case .int8:
//                    self.wrappedValue = try values.decode(Int8.self)
//                case .int16:
//                    self.wrappedValue = try values.decode(Int16.self)
//                case .int32:
//                    self.wrappedValue = try values.decode(Int32.self)
//                case .int64:
//                    self.wrappedValue = try values.decode(Int64.self)
//                case .uint:
//                    self.wrappedValue = try values.decode(UInt.self)
//                case .uint8:
//                    self.wrappedValue = try values.decode(UInt8.self)
//                case .uint16:
//                    self.wrappedValue = try values.decode(UInt16.self)
//                case .uint32:
//                    self.wrappedValue = try values.decode(UInt32.self)
//                case .uint64:
//                    self.wrappedValue = try values.decode(UInt64.self)
//                case .uuid:
//                    self.wrappedValue = try values.decode(UUID.self)
//                case .double:
//                    self.wrappedValue = try values.decode(Double.self)
//                case .float:
//                    self.wrappedValue = try values.decode(Float.self)
//                }
//            } catch(let error) {
//                print(error.localizedDescription)
//            }
//        }
//    }
//
//    init() {
//        wrappedValue = nil
//    }
//
//    func parameter<T: Codable>(_ type: T.Type = T.self) -> Parameter<T>? {
//        guard let anyCodableWrappedValue = wrappedValue as? AnyConcreteCodable else {
//            return Parameter<T>(.http(.body))
//        }
//        return nil
////             return anyCodableWrappedValue.typed(T.self)
//    }
//
//
//}

public struct AnyGenericCodable: AnyCodable {

    var wrappedValue: Codable.Type?
    var key: FieldKey?

    init(_ wrappedValue: Codable.Type? = nil) {
        self.wrappedValue = wrappedValue
    }

    init(_ wrappedValue: Codable.Type? = nil, key: FieldKey) {
        self.wrappedValue = wrappedValue
        self.key = key
    }

    public  func encode(to encoder: Encoder) throws {
//        wrappedValue?.encode(to: encoder)
    }

    public init(from decoder: Decoder) throws {
        self.init()
    }
    
    

}

public struct AnyConcreteCodable: AnyCodable {
    enum DecodeableType {
        case string, bool, int, int8, int16, int32, int64, uint, uint8, uint16, uint32, uint64, uuid, float, double
    }
    
    private var types: [DecodeableType] {
        [.int, .int8, .int16, .int32, .int64, .uint, .uint8, .uint16, .uint32, .uint64, .double, .float, .uuid, .bool, .string]
    }
    
    var wrappedValue: Codable? {
        didSet {
            wrappedType = .init(with: self)
        }
    }
    var wrappedType: TypeInferenceTest?
    
    init(_ wrappedType: TypeInferenceTest) {
        self.wrappedType = wrappedType
    }
    
    init(_ wrappedValue: Codable?) {
        setWrappedValue(wrappedValue)
    }

    private mutating func setWrappedValue(_ value: Codable?) {
        self.wrappedValue = value
    }
    
    public func encode(to encoder: Encoder) throws {
        try wrappedValue?.encode(to: encoder)
    }
    
    public init(from decoder: Decoder) throws {
        self.init()
        wrappedType = try TypeInferenceTest(from: decoder)
        print(wrappedType)
    }
    
    func executeFunctionOnTyp(_ function: @escaping ((String) -> ())) {
        function(self.wrappedValue as! String)
    }
    
    func executeFunctionOnTyp(_ function: @escaping ((Int) -> ())) {
        function(self.wrappedValue as! Int)
    }
    
    init() {
        wrappedValue = nil
        wrappedType = .noValue
    }
}

extension AnyConcreteCodable: LosslessStringConvertible {
    public init?(_ description: String) {
        print("description")
        print(description)
        self.init()
    }
    
    public var description: String {
        wrappedType?.description ?? wrappedValue.debugDescription
    }
    
    
}

enum TypeInferenceTest: Codable, Equatable {
    
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
    
    init(with anyCodable: AnyConcreteCodable?) {
        guard let wrappedValue = anyCodable.wra else { self = .noValue; return }
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
    
    func encode(to encoder: Encoder) throws {
        
    }

    case string(String), bool(Bool), int(Int), int8(Int8), int16(Int16), int32(Int32), int64(Int64), uint(UInt), uint8(UInt8), uint16(UInt16), uint32(UInt32), uint64(UInt64), uuid(UUID), float(Float), double(Double), noValue

    var description: String {
        String(reflecting: self)
    }
    
}

public protocol TypeSafeExecutable {
    func execute(_ function: ((String) -> Void), with type: String)
    func execute(_ function: ((Bool) -> Void), with type: Bool)
    func execute(_ function: ((Int) -> Void), with type: Int)
//        func execute(_ function: ((UUID) -> Void))
//        func execute<T: Float>(_ function: ((T) -> Void))
//        func execute<T: Int>(_ function: ((T) -> Void))
//        func execute<T: Int8>(_ function: ((T) -> Void))
//        func execute<T: Int16>(_ function: ((T) -> Void))
//        func execute<T: Int32>(_ function: ((T) -> Void))
//        func execute<T: Int64>(_ function: ((T) -> Void))
//        func execute<T: UInt8>(_ function: ((T) -> Void))
//        func execute<T: UInt16>(_ function: ((T) -> Void))
//        func execute<T: UInt32>(_ function: ((T) -> Void))
//        func execute<T: UInt64>(_ function: ((T) -> Void))
//        func execute<T: UUID>(_ function: ((T) -> Void))

}

public extension TypeSafeExecutable {
    
    func execute(_ function: @escaping ((Codable) -> Void), with type: AnyConcreteCodable) {
        guard let wrappedValue = type.wrappedValue else { return }
        print(wrappedValue)
        switch wrappedValue {
        case let value as Int:
            execute(function, with: value)
            break
        default:
            break
        }
    }
    
    /**
     builder.execute(type: value.type, execute: { value in
        builder.filter...
     }
     */
    
}

