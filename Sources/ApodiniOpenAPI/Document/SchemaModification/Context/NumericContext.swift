//
// Created by Andreas Bauer on 28.08.21.
//

import Foundation
import OpenAPIKit

struct NumericContext: JSONContext {
    var context: ContextName = .numeric

    enum Property: String {
        case multipleOf
        case maximum
        case minimum
    }

    static var multipleOf = PropertyDescription(context: Self.self, property: .multipleOf, type: Double.self)
    static var maximum = PropertyDescription(context: Self.self, property: .maximum, type: JSONSchema.NumericContext.Bound.self)
    static var minimum = PropertyDescription(context: Self.self, property: .minimum, type: JSONSchema.NumericContext.Bound.self)
}
