import Foundation




// MARK: Protocols and shit

/// Protocol indicating that the type is not nested, but rather directly embdeded into its parent type
public protocol LKProtobufferEmbeddedOneofType {}




public protocol LKAnyProtobufferMessageCodingKeys: Swift.CodingKey {
    static var allCases: [Self] { get }
}

public protocol LKProtobufferMessageCodingKeys: LKAnyProtobufferMessageCodingKeys & CaseIterable {}



public protocol LKAnyProtobufferCodableWithCustomFieldMapping {
    static func getCodingKeysType() -> LKAnyProtobufferMessageCodingKeys.Type
}

public protocol LKProtobufferCodableWithCustomFieldMapping: LKAnyProtobufferCodableWithCustomFieldMapping {
    associatedtype CodingKeys: RawRepresentable & CaseIterable & LKAnyProtobufferMessageCodingKeys where Self.CodingKeys.RawValue == Int
}

public extension LKProtobufferCodableWithCustomFieldMapping {
    static func getCodingKeysType() -> LKAnyProtobufferMessageCodingKeys.Type {
        CodingKeys.self
    }
}


public protocol LKProtobufferMessage {}
public typealias LKProtobufferMessageWithCustomFieldMapping = LKProtobufferMessage & LKProtobufferCodableWithCustomFieldMapping




/// A type which can become a primitive field in a protobuffer message
public protocol LKProtobufferPrimitive {}

extension Bool: LKProtobufferPrimitive {}
extension Int: LKProtobufferPrimitive {}
extension String: LKProtobufferPrimitive {}
extension Int64: LKProtobufferPrimitive {}
extension UInt64: LKProtobufferPrimitive {}
extension Int32: LKProtobufferPrimitive {}
extension UInt32: LKProtobufferPrimitive {}
extension Float: LKProtobufferPrimitive {}
extension Double: LKProtobufferPrimitive {}
// TODO add some more








public struct LKEmptyMessage: Codable, LKProtobufferMessage {}






/// A type which is mapped to the `bytes` type
public protocol __LKProtobufferBytesMappedType: LKProtobufferPrimitive {}

extension Data: __LKProtobufferBytesMappedType {}
extension Array: __LKProtobufferBytesMappedType, LKProtobufferPrimitive where Element == UInt8 {}




// MARK: Package & Typename

public protocol __Proto_TypeInNamespace {
    static var namespace: String { get }
}

public protocol __Proto_TypeWithCustomProtoName {
    static var protoTypeName: String { get }
}



// MARK: Repeated

/// A type which can be encoded into a `repeated` field.
protocol __LKProtobufRepeatedValueCodable {
    static var elementType: Any.Type { get }
    static var isPacked: Bool { get }
    init<Key: CodingKey>(decodingFrom decoder: Decoder, forKey key: Key, atFields fields: [LKProtobufFieldsMapping.FieldInfo]) throws
    /// Encodes the object's elements into the encoder, keyed by the specified key.
    func encodeElements<Key: CodingKey>(to encoder: Encoder, forKey key: Key) throws
}


extension Array: __LKProtobufRepeatedValueCodable where Element: Codable {
    static var elementType: Any.Type { Element.self }
    
    static var isPacked: Bool {
        switch LKGuessWireType(Element.self)! {
        case .varInt, ._32Bit, ._64Bit:
            return true
        case .lengthDelimited, .startGroup, .endGroup:
            return false
        }
    }
    
    init<Key: CodingKey>(decodingFrom decoder: Decoder, forKey key: Key, atFields fields: [LKProtobufFieldsMapping.FieldInfo]) throws {
        if Self.isPacked {
            fatalError()
        } else {
            let keyedContainer = try (decoder as! _LKProtobufferDecoder)._internalContainer(keyedBy: Key.self)
            //let keyedContainer = decoder.container(keyedBy: Key.self)
            let fields2 = keyedContainer.fields.getAll(forFieldNumber: key.getProtoFieldNumber())
            precondition(fields == fields2)
            self = try fields.map { fieldInfo -> Element in
                try keyedContainer.decode(Element.self, forKey: key, keyOffset: fieldInfo.keyOffset)
            }
        }
    }
    
    func encodeElements<Key: CodingKey>(to encoder: Encoder, forKey key: Key) throws {
        precondition(encoder is _LKProtobufferEncoder)
        if Self.isPacked {
            fatalError()
        } else {
            var keyedContainer = encoder.container(keyedBy: Key.self)
            for element in self {
                try keyedContainer.encode(element, forKey: key)
            }
        }
    }
}

