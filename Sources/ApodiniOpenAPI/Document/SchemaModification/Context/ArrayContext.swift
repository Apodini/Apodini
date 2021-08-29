//
// Created by Andreas Bauer on 28.08.21.
//

import Foundation
import OpenAPIKit

struct ArrayContext: JSONContext {
    var context: ContextName = .array

    enum Property: String {
        case items
        case maxItems
        case minItems
        case uniqueItems
    }

    static var items = PropertyDescription(context: Self.self, property: .items, type: JSONSchema.self)
    static var maxItems = PropertyDescription(context: Self.self, property: .maxItems, type: Int.self)
    static var minItems = PropertyDescription(context: Self.self, property: .minItems, type: Int.self)
    static var uniqueItems = PropertyDescription(context: Self.self, property: .uniqueItems, type: Bool.self)
}
