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
    enum Property: String {
        case multipleOf
        case maximum
        case minimum
    }

    static var multipleOf = PropertyDescription(context: Self.self, property: .multipleOf, type: Double.self)
    static var maximum = PropertyDescription(context: Self.self, property: .maximum, type: (Double, exclusive: Bool).self)
    static var minimum = PropertyDescription(context: Self.self, property: .minimum, type: (Double, exclusive: Bool).self)
}
