//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation

/// Represents the Protobuffer wire-types
/// See documentation for further info about the wire-types:
/// https://developers.google.com/protocol-buffers/docs/encoding#structure
public enum WireType: Int {
    case varInt = 0
    case bit64 = 1
    case lengthDelimited = 2
    case startGroup = 3 // deprecated & not supported by this implementation
    case endGroup = 4 // deprecated & not supported by this implementation
    case bit32 = 5
}
