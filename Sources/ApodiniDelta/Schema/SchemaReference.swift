//
//  File.swift
//  
//
//  Created by Eldi Cano on 21.03.21.
//

import Foundation

struct SchemaReference: Equatable, Hashable {
    let name: String

    static func reference(_ named: String) -> SchemaReference {
        SchemaReference(name: named)
    }

    static func reference(_ primitiveType: PrimitiveType) -> SchemaReference {
        .reference(primitiveType.description)
    }
}
