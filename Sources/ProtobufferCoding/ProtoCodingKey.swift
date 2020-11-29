//
//  ProtoCodable.swift
//  
//
//  Created by Moritz Schüll on 19.11.20.
//

import Foundation


protocol ProtoCodingKey: CodingKey {
    static func protoRawValue(_ key: CodingKey) throws -> Int
}

// Provide default implementation for mapCodingKey?
