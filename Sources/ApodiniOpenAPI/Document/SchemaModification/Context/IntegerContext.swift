//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
