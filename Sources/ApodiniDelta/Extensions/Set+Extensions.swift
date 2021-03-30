//
//  File.swift
//  
//
//  Created by Eldi Cano on 21.03.21.
//

import Foundation

extension Set where Element == Schema {
    func save(in schemaBuilder: inout SchemaBuilder) {
        schemaBuilder.addSchemas(self)
    }
}

extension Set {
    static var empty: Self { [] }
}
