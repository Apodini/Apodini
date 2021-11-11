import Foundation
@_implementationOnly import Runtime


enum WireType: UInt8, Hashable {
    /// int32, int64, uint32, uint64, sint32, sint64, bool, enum
    case varInt = 0
    /// 64-fixed64, sfixed64, double
    case _64Bit = 1
    /// string, bytes, embedded messages, packed repeated fields
    case lengthDelimited = 2
    /// groups (deprecated)
    @available(*, deprecated)
    case startGroup = 3
    /// groups (deprecated)
    @available(*, deprecated)
    case endGroup = 4
    ///fixed32, sfixed32, float
    case _32Bit = 5
}



/// Attempts to guess the protobuf wire type of the specified type.
/// - Note: This function should only be called with types that can actually be encoded to protobuf, i.e. types that conform to `Encodable`.
func GuessWireType(_ type: Any.Type) -> WireType? {
    if type == String.self {
        return .lengthDelimited
    } else if type == Int.self {
        return .varInt
    } else if type == Float.self {
        return ._32Bit
    } else if type == Double.self {
        return ._64Bit
    } else if let TI = try? typeInfo(of: type) {
        // Try to determine the wire type based on the kind of type we're dealing with.
        // For example, all structs that didn't match any of the explicitly-checked-for types above can be assumed to be length-delimited
        switch TI.kind {
        case .struct:
            return .lengthDelimited
        case .enum:
            // TODO do something based on the raw value?
            if (type as? AnyProtobufEnumWithAssociatedValues.Type) != nil {
                // should be unreachable, so we can probably remove this check
                // TODO we have to ignore the key, and the wire type is determined based on the value set!!!
                //return .lengthDelimited
            }
            if (type as? AnyProtobufEnum.Type) != nil {
                return .varInt
            }
            fatalError("Unhandled: \(type)") // TODO how should this be handled?
        case .optional:
            fatalError() // TODO how should this be handled?
        case .opaque:
            fatalError() // TODO how should this be handled? If at all...
        case .tuple:
            fatalError() // TODO how should this be handled? If at all...
        case .function:
            fatalError() // TODO how should this be handled? If at all...
        case .existential:
            fatalError() // TODO how should this be handled? If at all...
        case .metatype:
            fatalError() // TODO how should this be handled? If at all...
        case .objCClassWrapper:
            fatalError() // TODO how should this be handled? If at all...
        case .existentialMetatype:
            fatalError() // TODO how should this be handled? If at all...
        case .foreignClass:
            fatalError() // TODO how should this be handled? If at all...
        case .heapLocalVariable:
            fatalError() // TODO how should this be handled? If at all...
        case .heapGenericLocalVariable:
            fatalError() // TODO how should this be handled? If at all...
        case .errorObject:
            fatalError() // TODO how should this be handled?
        case .class:
            fatalError() // TODO how should this be handled?
        }
    } else {
        fatalError()
    }
}


/// Attempts to guess the protobuf wire type of the specified value.
/// - Note: This function should only be called with values of types that can actually be encoded to protobuf, i.e. types that conform to `Encodable`.
func GuessWireType(_ value: Any) -> WireType? { // TODO remove this function!
    return GuessWireType(type(of: value))
}

