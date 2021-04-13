//
//  File.swift
//  
//
//  Created by Eldi Cano on 20.03.21.
//

import Foundation

extension PrimitiveType: ComparableProperty {}

extension PrimitiveType: CustomStringConvertible {
    public var description: String { rawValue }
}

extension PrimitiveType {
    var schemaName: SchemaName {
        .init(String(reflecting: swiftType))
    }
}
