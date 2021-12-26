//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import NIO
import ApodiniUtils


/// Conforming to this protocol indicates that a (message) type does not get encoded into a nested field,
/// but rather direct into its parent type (i.e. the type of which it is a property).
/// - Note: This is an internal protocol, which currently is only used for handling enums w/ associated values, and should not be conformed to outside this module.
public protocol _ProtobufEmbeddedType {}

/// Type-erased version of ProtobufMessageCodingKeys
public protocol AnyProtobufMessageCodingKeys: Swift.CodingKey {
    static var allCases: [Self] { get }
}

/// A type which models a coding key used by a proto-codable type
public protocol ProtobufMessageCodingKeys: AnyProtobufMessageCodingKeys & CaseIterable {}


/// Type-erased version of `ProtobufTypeWithCustomFieldMapping`
public protocol AnyProtobufTypeWithCustomFieldMapping {
    /// Returns the type's `CodingKeys` type.
    static func getCodingKeysType() -> AnyProtobufMessageCodingKeys.Type
}


/// A protobuf-codable type that defines a custom field mapping, via its nested `CodingKeys` type.
public protocol ProtobufTypeWithCustomFieldMapping: AnyProtobufTypeWithCustomFieldMapping {
    associatedtype CodingKeys: RawRepresentable & CaseIterable & AnyProtobufMessageCodingKeys where Self.CodingKeys.RawValue == Int
}

public extension ProtobufTypeWithCustomFieldMapping {
    /// :nodoc:
    static func getCodingKeysType() -> AnyProtobufMessageCodingKeys.Type {
        CodingKeys.self
    }
}


/// A type that is to become a  `message` type in protobuf.
/// - Note: Conforming to this type is optional.
///         The `ProtobufEncoder` and `ProtobufDecoder`, as well as the proto schema can, for most types automatically detect
///         whether or not it should be mapped to a message type. This protocol exists to force a type be handled as a message type
///         in cases where it is incorrectly not handled as a message type.
public protocol ProtobufMessage: __ProtoTypeWithReservedFields {}

/// A type which is a message that defines a custom field mapping
public typealias ProtobufMessageWithCustomFieldMapping = ProtobufMessage & ProtobufTypeWithCustomFieldMapping


/// Indicates that a type should be handled using the proto2 coding behaviour.
/// By default, all types use the proto3 behaviour, conforming to this protocol allows types to customise that.
/// - Note: This protocol is not propagated to nested types, but instead _every single_ type has to conform to it separately.
public protocol Proto2Codable {}


// MARK: Reserved Fields

/// A reserved field in a message or enum
public enum ProtoReservedField: Hashable {
    case range(ClosedRange<Int32>)
    case index(Int32)
    case name(String)
}


/// Protocol for defining a type with a set of reserved field numbers and names.
/// - Note: **Do not** conform your custom types to this protocol.
///         Use `ProtobufMessage` or `ProtobufEnum` instead.
public protocol __ProtoTypeWithReservedFields {
    /// The set of reserved fields in this type.
    static var reservedFields: Set<ProtoReservedField> { get }
}

extension __ProtoTypeWithReservedFields {
    /// The set of reserved fields in this type.
    public static var reservedFields: Set<ProtoReservedField> { [] }
}


extension Set where Element == ProtoReservedField {
    /// Extracts all reserved field names
    public func allReservedNames() -> [String] {
        self.compactMap {
            switch $0 {
            case .range, .index:
                return nil
            case .name(let name):
                return name
            }
        }
    }
    
    /// Extracts all reserved field indices and ranges
    public func allReservedFieldNumbers() -> (indices: [Int32], ranges: [ClosedRange<Int32>]) {
        var indices: [Int32] = []
        var ranges: [ClosedRange<Int32>] = []
        for element in self {
            switch element {
            case .range(let range):
                ranges.append(range)
            case .index(let idx):
                indices.append(idx)
            case .name:
                break
            }
        }
        return (indices, ranges)
    }
}


/// A type which can become a primitive field in a protobuffer message
protocol ProtobufPrimitive {}

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


/// A type which can be initialised from a 32-bit value
internal protocol Proto32BitValueInitialisable {
    init?(proto32BitValue: UInt32)
}

extension Float: Proto32BitValueInitialisable {
    init?(proto32BitValue: UInt32) {
        self.init(bitPattern: proto32BitValue)
    }
}


/// A type which can be initialised from a 64-bit value
internal protocol Proto64BitValueInitialisable {
    init?(proto64BitValue: UInt64)
}

extension Double: Proto64BitValueInitialisable {
    init?(proto64BitValue: UInt64) {
        self.init(bitPattern: proto64BitValue)
    }
}


/// An empty message type, internally mapped to `google.protobuf.Empty`
public struct EmptyMessage: Codable, ProtobufMessage, ProtoTypeInPackage, ProtoTypeWithCustomProtoName {
    public static var package: ProtobufPackageUnit {
        ProtobufPackageUnit(packageName: "google.protobuf", filename: "google/protobuf/empty.proto")
    }
    public static let protoTypename = "Empty"
}


/// A type which is mapped to the `bytes` type
protocol ProtobufBytesMapped: ProtobufPrimitive {
    init(rawBytes: ByteBuffer) throws
    func asRawBytes() throws -> ByteBuffer
}

extension Data: ProtobufBytesMapped {
    init(rawBytes: ByteBuffer) throws {
        self.init(buffer: rawBytes)
    }
    func asRawBytes() throws -> ByteBuffer {
        ByteBuffer(data: self)
    }
}

extension Array: ProtobufBytesMapped, ProtobufPrimitive where Element == UInt8 {
    init(rawBytes: ByteBuffer) throws {
        if let bytes = rawBytes.getBytes(at: rawBytes.readerIndex, length: rawBytes.readableBytes) {
            self = bytes
        } else {
            throw ProtoDecodingError.other("Unable to get bytes from ByteBuffer")
        }
    }
    func asRawBytes() throws -> ByteBuffer {
        ByteBuffer(bytes: self)
    }
}


// MARK: Package & Typename

/// A protobuffer package name. Should be in reverse DNS notation.
public struct ProtobufPackageUnit: Hashable {
    static let inlineInParentTypePackage = ProtobufPackageUnit(packageName: "<inlineInParentTypePackage>")
    
    public let packageName: String
    public let filename: String
    
    public init(packageName: String, filename: String) {
        self.packageName = packageName
        self.filename = filename
    }
    
    public init(packageName: String) {
        self.packageName = packageName
        self.filename = "\(packageName.replacingOccurrences(of: ".", with: "/")).proto"
    }
}

/// A type which can specify the protobuf package into which it belongs.
/// Use this protocol to explicitly move a type into a proto package.
/// If a type does not conform to this protocol, it will be moved into the default package.
/// - Note: Protobuffer package are not inherited, meaning that if a type defines a custom package, and that type contains
///         other nested types, these other nested types **must** also conform to this protocol, and specify the exact same package name.
public protocol ProtoTypeInPackage {
    /// The type's protobuffer package name
    static var package: ProtobufPackageUnit { get }
}


/// Use this protocol to define a custom proto type for a Swift type.
/// By default, the type's Swift name is used, which might not always be the desired name.
/// - Note: This only works for "leaf" types, i.e. types that do not contain any other nested types.
public protocol ProtoTypeWithCustomProtoName {
    /// This type's protobuffer typename
    static var protoTypename: String { get }
}
