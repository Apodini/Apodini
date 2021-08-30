//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

struct StringContext: JSONContext {
    enum Property: String {
        case maxLength
        case minLength
        case pattern
    }

    static var maxLength = PropertyDescription(context: Self.self, property: .maxLength, type: Int.self)
    static var minLength = PropertyDescription(context: Self.self, property: .minLength, type: Int.self)
    static var pattern = PropertyDescription(context: Self.self, property: .pattern, type: String.self)
}
