//
// Created by Andreas Bauer on 28.08.21.
//

import Foundation

struct StringContext: JSONContext {
    var context: ContextName = .string

    enum Property: String {
        case maxLength
        case minLength
        case pattern
    }

    static var maxLength = PropertyDescription(context: Self.self, property: .maxLength, type: Int.self)
    static var minLength = PropertyDescription(context: Self.self, property: .minLength, type: Int.self)
    static var pattern = PropertyDescription(context: Self.self, property: .pattern, type: String.self)
}
