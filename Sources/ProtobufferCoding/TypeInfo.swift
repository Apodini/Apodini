import Foundation
import ApodiniUtils

// swiftlint:disable discouraged_optional_boolean

// MARK: - Supported data types
/// Supported primitive types.
private let primitiveSupportedTypes: [Any.Type] = [
    String.self,
    Bool.self,
    Int.self,
    Int32.self,
    Int64.self,
    UInt.self,
    UInt32.self,
    UInt64.self,
    Double.self,
    Float.self,
    Data.self,
    String?.self,
    Bool?.self,
    Int?.self,
    Int32?.self,
    Int64?.self,
    UInt?.self,
    UInt32?.self,
    UInt64?.self,
    Double?.self,
    Float?.self,
    Data?.self
]

/// Supported arrays of primitive types.
private let primitiveSupportedArrayTypes: [Any.Type] = [
    [String].self,
    [Bool].self,
    [Int].self,
    [Int32].self,
    [Int64].self,
    [UInt].self,
    [UInt32].self,
    [UInt64].self,
    [Double].self,
    [Float].self,
    [Data].self,
    [String?].self,
    [Bool?].self,
    [Int?].self,
    [Int32?].self,
    [Int64?].self,
    [UInt?].self,
    [UInt32?].self,
    [UInt64?].self,
    [Double?].self,
    [Float?].self,
    [Data?].self
]

internal func isPrimitiveSupported(_ type: Any.Type) -> Bool {
    primitiveSupportedTypes.contains(where: { $0 == type })
}

internal func isPrimitiveSupportedArray(_ type: Any.Type) -> Bool {
    primitiveSupportedArrayTypes.contains(where: { $0 == type })
}
