import Foundation
@_implementationOnly import Runtime

// MARK: - Supported data types
/// Supported primitive types.
private let primitiveSupportedTypes: [Any.Type] = [
    String.self,
    Bool.self,
    Int32.self,
    Int64.self,
    UInt32.self,
    UInt64.self,
    Double.self,
    Float.self,
    Data.self
]

/// Supported arrays of primitive types.
private let primitiveSupportedArrayTypes: [Any.Type] = [
    [String].self,
    [Bool].self,
    [Int32].self,
    [Int64].self,
    [UInt32].self,
    [UInt64].self,
    [Double].self,
    [Float].self,
    [Data].self,
    [String?].self,
    [Bool?].self,
    [Int32?].self,
    [Int64?].self,
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

// MARK: - Collection
internal func isCollection(_ any: Any) -> Bool {
    switch Mirror(reflecting: any).displayStyle {
    case .some(.collection):
        return true
    default:
        return false
    }
}

// MARK: - Optional
internal func isOptional(_ type: Any.Type) -> Bool {
    do {
        let typeInfo = try Runtime.typeInfo(of: type)
        return typeInfo.kind == .optional
    } catch {
        // typeInfo(of:) only throws if the `Kind` enum isn't one of the supported cases:
        //  .struct, .class, .existential, .tuple, .enum, .optional.
        // Thus if it throws, we know for sure that it isn't a optional.
        return false
    }
}
