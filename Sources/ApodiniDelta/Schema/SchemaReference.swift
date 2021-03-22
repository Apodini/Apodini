//
//  File.swift
//  
//
//  Created by Eldi Cano on 21.03.21.
//

import Foundation

struct SchemaReference: Equatable, Hashable, Codable {
    let schemaName: String
}

extension SchemaReference {
    static func reference(_ named: String) -> SchemaReference {
        SchemaReference(schemaName: named)
    }

    static func reference(_ primitiveType: PrimitiveType) -> SchemaReference {
        .reference(primitiveType.description)
    }

    static var empty: SchemaReference {
        .reference("")
    }
}
