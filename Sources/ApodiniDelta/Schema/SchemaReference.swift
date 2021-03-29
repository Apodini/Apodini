//
//  File.swift
//  
//
//  Created by Eldi Cano on 21.03.21.
//

import Foundation

/// A reference to a schema holding the schema name
struct SchemaReference: Equatable, Hashable, Codable {
    let schemaName: String
}

// MARK: - Convenience
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

// MARK: - ComparableProperty
extension SchemaReference: ComparableProperty {}
