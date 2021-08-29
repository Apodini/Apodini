//
// Created by Andreas Bauer on 28.08.21.
//

import Foundation
import OpenAPIKit

struct IntegerContext: JSONContext {
    var context: ContextName = .integer

    enum Property: String {
        case multipleOf
        case maximum
        case minimum
    }

    static var multipleOf = PropertyDescription(context: Self.self, property: .multipleOf, type: Int.self)
    static var maximum = PropertyDescription(context: Self.self, property: .maximum, type: JSONSchema.IntegerContext.Bound.self)
    static var minimum = PropertyDescription(context: Self.self, property: .minimum, type: JSONSchema.IntegerContext.Bound.self)
}
