//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
@_implementationOnly import Runtime
import ApodiniUtils


enum WireType: UInt8, Hashable {
    /// int32, int64, uint32, uint64, sint32, sint64, bool, enum
    case varInt = 0
    /// ffixed64, sfixed64, double
    case _64Bit = 1 // swiftlint:disable:this identifier_name
    /// string, bytes, embedded messages, packed repeated fields
    case lengthDelimited = 2
    /// groups (deprecated)
    @available(*, deprecated)
    case startGroup = 3
    /// groups (deprecated)
    @available(*, deprecated)
    case endGroup = 4
    ///fixed32, sfixed32, float
    case _32Bit = 5 // swiftlint:disable:this identifier_name
}


/// Attempts to guess the protobuf wire type of the specified type.
/// - Note: This function should only be called with types that can actually be encoded to protobuf, i.e. types that conform to `Encodable`.
func guessWireType(_ type: Any.Type) -> WireType? { // swiftlint:disable:this cyclomatic_complexity
    if let optionalTy = type as? AnyOptional.Type {
        return guessWireType(optionalTy.wrappedType)
    } else if type == String.self {
        return .lengthDelimited
    } else if case let types = Set(Bool.self, Int.self, UInt.self, Int32.self, UInt32.self, Int64.self, UInt64.self),
              types.contains(type) || (type as? AnyProtobufEnum.Type != nil) {
        return .varInt
    } else if type == Float.self {
        return ._32Bit
    } else if type == Double.self {
        return ._64Bit
    } else if type as? ProtobufBytesMapped.Type != nil {
        return .lengthDelimited
    } else if let repeatedTy = type as? ProtobufRepeated.Type {
        return repeatedTy.isPacked ? .lengthDelimited : guessWireType(repeatedTy.elementType)
    } else if let typeInfo = try? Runtime.typeInfo(of: type) {
        // Try to determine the wire type based on the kind of type we're dealing with.
        // For example, all structs that didn't match any of the explicitly-checked-for types above can be assumed to be length-delimited
        switch typeInfo.kind {
        case .struct:
            return .lengthDelimited
        case .enum:
            if type as? AnyProtobufEnum.Type != nil {
                return .varInt
            } else {
                return nil
            }
        case .optional, .opaque, .tuple, .function, .existential, .metatype, .objCClassWrapper,
                .existentialMetatype, .foreignClass, .heapLocalVariable, .heapGenericLocalVariable,
                .errorObject, .class:
            return nil
        }
    } else {
        return nil
    }
}
