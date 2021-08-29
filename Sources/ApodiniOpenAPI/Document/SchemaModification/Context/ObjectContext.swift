//
// Created by Andreas Bauer on 28.08.21.
//

import Foundation
import OpenAPIKit

struct ObjectContext: JSONContext {
    var context: ContextName = .object

    enum Property: String {
        case properties
        case additionalProperties
        case maxProperties
        case minProperties
    }

    static var properties = PropertyDescription(context: Self.self, property: .properties, type: [String: JSONSchema].self)
    static var additionalProperties = PropertyDescription(context: Self.self, property: .additionalProperties, type: Either<Bool, JSONSchema>.self)
    static var maxProperties = PropertyDescription(context: Self.self, property: .maxProperties, type: Int.self)
    static var minProperties = PropertyDescription(context: Self.self, property: .minProperties, type: Int.self)
}
