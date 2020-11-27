//
//  ProtoCodable.swift
//  
//
//  Created by Moritz Schüll on 19.11.20.
//

import Foundation


protocol ProtoCodingKey: CodingKey {
    static func mapCodingKey(_ key: CodingKey) throws -> Int?
}

// TODO Provide default implementation for mapCodingKey?
