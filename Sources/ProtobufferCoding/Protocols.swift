import Foundation



/// Conforming to this protocol indicates that a (message) type does not get encoded into a nested field,
/// but rather direct into its parent type (i.e. the type of which it is a property).
/// - Note: This is an internal protocol, which currently is only used for handling enums w/ associated values, and should not be conformed to outside this module.
public protocol _ProtobufEmbeddedType {}



public protocol AnyProtobufMessageCodingKeys: Swift.CodingKey {
    static var allCases: [Self] { get }
}

public protocol ProtobufMessageCodingKeys: AnyProtobufMessageCodingKeys & CaseIterable {}



public protocol AnyProtobufTypeWithCustomFieldMapping {
    static func getCodingKeysType() -> AnyProtobufMessageCodingKeys.Type
}

public protocol ProtobufTypeWithCustomFieldMapping: AnyProtobufTypeWithCustomFieldMapping {
    associatedtype CodingKeys: RawRepresentable & CaseIterable & AnyProtobufMessageCodingKeys where Self.CodingKeys.RawValue == Int
}

public extension ProtobufTypeWithCustomFieldMapping {
    static func getCodingKeysType() -> AnyProtobufMessageCodingKeys.Type {
        CodingKeys.self
    }
}


/// A type that is to become a  `message` type in protobuf.
public protocol ProtobufMessage {}

public typealias ProtobufMessageWithCustomFieldMapping = ProtobufMessage & ProtobufTypeWithCustomFieldMapping




/// A type which can become a primitive field in a protobuffer message
public protocol ProtobufPrimitive {}

extension Bool: ProtobufPrimitive {}
extension Int: ProtobufPrimitive {}
extension String: ProtobufPrimitive {}
extension Int64: ProtobufPrimitive {}
extension UInt64: ProtobufPrimitive {}
extension Int32: ProtobufPrimitive {}
extension UInt32: ProtobufPrimitive {}
extension Float: ProtobufPrimitive {}
extension Double: ProtobufPrimitive {}



/// An empty message type, similar to `google.protobuf.Empty`
public struct EmptyMessage: Codable, ProtobufMessage {}



/// A type which is mapped to the `bytes` type
public protocol ProtobufBytesMapped: ProtobufPrimitive {}

extension Data: ProtobufBytesMapped {}
extension Array: ProtobufBytesMapped, ProtobufPrimitive where Element == UInt8 {} // TODO can/should we remove the primitive conformance here?




// MARK: Package & Typename


public struct ProtobufPackageName: RawRepresentable, Hashable {
    public static let `default` = Self("<default>") // intentionally using a string that would be an invalid package name...
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

/// A type which can specify the protobuf package into which it belongs
public protocol ProtoTypeInPackage {
    static var package: ProtobufPackageName { get }
}


public protocol ProtoTypeWithCustomProtoName { // TODO what about having message/enum/assocEnum inherit from this, simply using the current typename as the default value?
    static var protoTypename: String { get }
}



// MARK: Repeated

/// A type which can be encoded into a `repeated` field.
protocol ProtobufRepeated {
    static var elementType: Any.Type { get }
    static var isPacked: Bool { get }
    init<Key: CodingKey>(decodingFrom decoder: Decoder, forKey key: Key, atFields fields: [ProtobufFieldInfo]) throws
    /// Encodes the object's elements into the encoder, keyed by the specified key.
    func encodeElements<Key: CodingKey>(to encoder: Encoder, forKey key: Key) throws
}


extension Array: ProtobufRepeated where Element: Codable {
    static var elementType: Any.Type { Element.self }
    
    static var isPacked: Bool {
        switch GuessWireType(Element.self)! {
        case .varInt, ._32Bit, ._64Bit:
            return true
        case .lengthDelimited, .startGroup, .endGroup:
            return false
        }
    }
    
    init<Key: CodingKey>(decodingFrom decoder: Decoder, forKey key: Key, atFields fields: [ProtobufFieldInfo]) throws {
        if Self.isPacked {
            fatalError() // TODO
        } else {
            let keyedContainer = try (decoder as! _ProtobufferDecoder)._internalContainer(keyedBy: Key.self)
            let fields2 = keyedContainer.fields.getAll(forFieldNumber: key.getProtoFieldNumber())
            precondition(fields == fields2)
            self = try fields.map { fieldInfo -> Element in
                try keyedContainer.decode(Element.self, forKey: key, keyOffset: fieldInfo.keyOffset)
            }
        }
    }
    
    func encodeElements<Key: CodingKey>(to encoder: Encoder, forKey key: Key) throws {
        precondition(encoder is _ProtobufferEncoder)
        if Self.isPacked {
            fatalError() // TODO
        } else {
            var keyedContainer = encoder.container(keyedBy: Key.self)
            for element in self {
                try keyedContainer.encode(element, forKey: key)
            }
        }
    }
}

