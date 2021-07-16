//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

public enum IntegerWidthCodingStrategy {
    /// `Int`s and `UInt`s are encoded with a 32 bit wide field.
    case thirtyTwo
    /// `Int`s and `UInt`s are encoded with a 64 bit wide field.
    case sixtyFour
    
    /// `.native` is derived from the target's underlying architecture.
    static let native: Self = {
        if MemoryLayout<Int>.size == 4 {
            return .thirtyTwo
        } else {
            return .sixtyFour
        }
    }()
}
