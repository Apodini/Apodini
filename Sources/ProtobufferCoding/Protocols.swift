import Foundation
import NIO
import ApodiniUtils



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


/// Indicates that a type should be handled using the proto2 coding behaviour.
/// By default, all types use the proto3 behaviour, conforming to this protocol allows types to customise that.
/// - Note: This protocol is not propagated to nested types, but instead _every single_ type has to conform to it separately.
public protocol Proto2Codable {}




/// A type which can become a primitive field in a protobuffer message
public protocol ProtobufPrimitive {} // TODO can we make this private? considering we don't reallly want someone importing the target to be able to add custom conformances

extension Bool: ProtobufPrimitive {}
extension Int: ProtobufPrimitive {}
extension UInt: ProtobufPrimitive {}
extension Int32: ProtobufPrimitive {}
extension UInt32: ProtobufPrimitive {}
extension Int64: ProtobufPrimitive {}
extension UInt64: ProtobufPrimitive {}
extension Float: ProtobufPrimitive {}
extension Double: ProtobufPrimitive {}
extension String: ProtobufPrimitive {}

//extension Optional: ProtobufPrimitive where Wrapped: ProtobufPrimitive {} // TODO do we want this? prob needed for the schema!????




internal protocol ProtoVarIntInitialisable {
    init?(varInt: UInt64)
}


extension Bool: ProtoVarIntInitialisable {
    init?(varInt: UInt64) {
        switch varInt {
        case 0:
            self = false
        case 1:
            self = true
        default:
            return nil
        }
    }
}

extension Int: ProtoVarIntInitialisable {
    init?(varInt: UInt64) {
        self.init(truncatingIfNeeded: varInt)
    }
}

extension UInt: ProtoVarIntInitialisable {
    init?(varInt: UInt64) {
        self.init(truncatingIfNeeded: varInt)
    }
}

extension Int64: ProtoVarIntInitialisable {
    init?(varInt: UInt64) {
        self.init(truncatingIfNeeded: varInt)
    }
}

extension UInt64: ProtoVarIntInitialisable {
    init?(varInt: UInt64) {
        self = varInt
    }
}

extension Int32: ProtoVarIntInitialisable {
    init?(varInt: UInt64) {
        self.init(varInt)
    }
}

extension UInt32: ProtoVarIntInitialisable {
    init?(varInt: UInt64) {
        self.init(varInt)
    }
}



/// A type which can be initialised from a 32-bit value // TODO add some conformances?
internal protocol Proto32BitValueInitialisable {
    init?(proto32BitValue: UInt32)
}


extension Float: Proto32BitValueInitialisable {
    init?(proto32BitValue: UInt32) {
        self.init(bitPattern: proto32BitValue)
    }
}


/// A type which can be initialised from a 64-bit value // TODO add some conformances?
internal protocol Proto64BitValueInitialisable {
    init?(proto64BitValue: UInt64)
}


extension Double: Proto64BitValueInitialisable {
    init?(proto64BitValue: UInt64) {
        self.init(bitPattern: proto64BitValue)
    }
}



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
        guard !fields.isEmpty else {
            self = []
            return
        }
        let decoder = decoder as! _ProtobufferDecoder
        if Self.isPacked {
//            fatalError() // TODO
            guard fields.count == 1 else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Key '\(key.getProtoFieldNumber())' occurs multiple times in the encoded message, which is invalid for packed repeated fields.",
                    underlyingError: nil
                ))
            }
            precondition(fields[0].wireType == .lengthDelimited)
            let (fieldInfo, fieldValueBytesImmut) = try decoder._internalContainer(keyedBy: Key.self).getFieldInfoAndValueBytes(forKey: key, atOffset: nil)
            var fieldValueBytes = fieldValueBytesImmut
            precondition(fieldInfo == fields[0])
            let fieldLength = try fieldValueBytes.readVarInt()
            precondition(fieldValueBytes.readableBytes == Int(fieldLength))
            switch GuessWireType(Element.self)! {
            case .varInt: // valueBytes is a bunch of varInts following each other
                let elementTy = Element.self as! ProtoVarIntInitialisable.Type
                var elements: [Element] = []
                while fieldValueBytes.readableBytes > 0 {
                    let varInt = try fieldValueBytes.readVarInt()
                    let element = elementTy.init(varInt: varInt)!
                    elements.append(element as! Element)
                }
//                while let varInt = try? fieldValueBytes.readVarInt() {
//                    let element = elementTy.init(varInt: varInt)!
//                    elements.append(element as! Element)
//                }
                self = elements
                return
            case ._32Bit:
                let u32Size = MemoryLayout<UInt32>.size
                // valueBytes is a bunch of 32-bit values following each other
                precondition(fieldValueBytes.readableBytes.isMultiple(of: u32Size), "Invalid length for packed array of 32-bit values")
                let numElements = fieldValueBytes.readableBytes / u32Size
                let elementTy = Element.self as! Proto32BitValueInitialisable.Type
                self = try (0..<numElements).map { idx in
                    if let u32Val = fieldValueBytes.readInteger(endianness: .little, as: UInt32.self) { // TODO the proto docs don't really say much about the endianness of u32 values. Is this correct? (it;s not a var int, and they only state that all varInts ar LSB first)
                        if let element = elementTy.init(proto32BitValue: u32Val) {
                            return element as! Element
                        } else {
                            throw DecodingError.dataCorrupted(.init(
                                codingPath: decoder.codingPath.appending(key), // TODO append one more element to indicate the index into the array? maybe use the FixedCodingKey for this?
                                debugDescription: "Unable to initialize '\(Element.self)' from u32 value \(u32Val)",
                                underlyingError: nil
                            ))
                        }
                    } else {
                        throw DecodingError.dataCorrupted(.init(
                            codingPath: decoder.codingPath.appending(key),
                            debugDescription: "Unable to read element at index \(idx) in packed repeated field.",
                            underlyingError: nil
                        ))
                    }
                }
            case ._64Bit: // valueBytes is a bunch of 64-bit values following each other
                let u64Size = MemoryLayout<UInt64>.size
                precondition(fieldValueBytes.readableBytes.isMultiple(of: u64Size), "Invalid length for packed array of 64-bit values")
                let numElements = fieldValueBytes.readableBytes / u64Size
                let elementTy = Element.self as! Proto64BitValueInitialisable.Type
                self = try (0..<numElements).map { idx in
                    if let u64Val = fieldValueBytes.readInteger(endianness: .little, as: UInt64.self) { // TODO the proto docs don't really say much about the endianness of u64 values. Is this correct? (it;s not a var int, and they only state that all varInts ar LSB first)
                        if let element = elementTy.init(proto64BitValue: u64Val) {
                            return element as! Element
                        } else {
                            throw DecodingError.dataCorrupted(.init(
                                codingPath: decoder.codingPath.appending(key), // TODO append one more element to indicate the index into the array? maybe use the FixedCodingKey for this?
                                debugDescription: "Unable to initialize '\(Element.self)' from u64 value \(u64Val)",
                                underlyingError: nil
                            ))
                        }
                    } else {
                        throw DecodingError.dataCorrupted(.init(
                            codingPath: decoder.codingPath.appending(key),
                            debugDescription: "Unable to read element at index \(idx) in packed repeated field.",
                            underlyingError: nil
                        ))
                    }
                }
            case .lengthDelimited, .startGroup, .endGroup:
                fatalError("Unsupported wire type for packed repeated field") // TODO throw an error instead!
            }
//            let keyedContainer = try decoder._internalContainer(keyedBy: Key.self)
//            guard keyedContainer.fields.getAll(forFieldNumber: key.getProtoFieldNumber()).count <= 1 else {
//                throw DecodingError.dataCorrupted(DecodingError.Context(
//                    codingPath: decoder,
//                    debugDescription: "Key '\(key.getProtoFieldNumber())' occurs multiple times in the encoded message, which is invalid for packed repeated fields.",
//                    underlyingError: nil
//                ))
//            }
//            let (fieldInfo, valueBytes) = keyedContainer.getFieldInfoAndValueBytes(forKey: key, atOffset: nil)
//            precondition(fieldInfo.wireType == .lengthDelimited)
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
        guard !isEmpty else {
            return
        }
        //precondition(encoder is _ProtobufferEncoder)
        let encoder = encoder as! _ProtobufferEncoder
        if Self.isPacked {
//            fatalError() // TODO
//            let elementsBufferRef = Box(ByteBuffer())
//            let encoder = _ProtobufferEncoder(codingPath: encoder.codingPath, dstBufferRef: bufferRef)
//            var unkeyedContainer = encoder.unkeyedContainer()
//            for element in self {
//                try unkeyedContainer.encode(element)
//            }
//            let
//            (encoder as! _ProtobufferEncoder).dstBufferRef
            let dstBufferRef = (encoder as! _ProtobufferEncoder).dstBufferRef
            let oldWriterIdx = dstBufferRef.value.writerIndex
            dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: .lengthDelimited)
            let elementsBuffer = try { () -> ByteBuffer in
                let elementsBuffer = Box(ByteBuffer())
                let elementsEncoder = _ProtobufferEncoder(codingPath: encoder.codingPath, dstBufferRef: elementsBuffer, context: encoder.context)
                var elementsContainer = elementsEncoder.unkeyedContainer()
                for element in self {
                    try elementsContainer.encode(element)
                }
                return elementsBuffer.value
            }()
            dstBufferRef.value.writeProtoLengthDelimited(elementsBuffer)
//            var unkeyedContainer = encoder.unkeyedContainer()
//            for element in self {
//                try unkeyedContainer.encode(element)
//            }
//            let newWriterIdx = dstBufferRef.value.writerIndex
//            let newBytes = dstBufferRef.value.getBytes(at: oldWriterIdx, length: newWriterIdx - oldWriterIdx)!
//            print(newBytes)
//            fatalError()
        } else {
            var keyedContainer = encoder.container(keyedBy: Key.self)
            for element in self {
                try keyedContainer.encode(element, forKey: key)
            }
        }
    }
}

