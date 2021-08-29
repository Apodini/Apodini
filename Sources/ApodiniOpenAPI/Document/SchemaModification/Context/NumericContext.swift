//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
