//
//  WireType.swift
//  
//
//  Created by Moritz Schüll on 27.11.20.
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
