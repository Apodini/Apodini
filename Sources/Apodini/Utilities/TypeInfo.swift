//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

// MARK: - Supported Scalar Types
private let supportedScalarTypes: Set<ObjectIdentifier> = [
    ObjectIdentifier(Int.self),
    ObjectIdentifier(Int32.self),
    ObjectIdentifier(Int64.self),
    ObjectIdentifier(UInt.self),
    ObjectIdentifier(UInt32.self),
    ObjectIdentifier(UInt64.self),
    ObjectIdentifier(Bool.self),
    ObjectIdentifier(String.self),
    ObjectIdentifier(Double.self),
    ObjectIdentifier(Float.self)
]


/// Whether the type is a supported scalar type
public func isSupportedScalarType(_ type: Any.Type) -> Bool {
    supportedScalarTypes.contains(ObjectIdentifier(type))
}
