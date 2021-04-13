//
//  File.swift
//  
//
//  Created by Eldi Cano on 21.03.21.
//

import Foundation

/// Holds the name of the type in its `value` property containing the name of the Module where it is defined to
/// e.g. `Swift.Int`, and simply `Int` in its `name` property.
class SchemaName: PropertyValueWrapper<String> {
    /// The name of the type
    var name: String {
        if let name = value.split(separator: ".").last {
            return String(name)
        }
        return value
    }

    static var empty: SchemaName { .init("") }
}

extension SchemaName: DeltaIdentifiable {
    var deltaIdentifier: DeltaIdentifier { .init(value) }
}
