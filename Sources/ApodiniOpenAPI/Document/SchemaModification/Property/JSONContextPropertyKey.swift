//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

struct JSONContextPropertyKey<Context: JSONContext>: Hashable {
    let context: Context.Type
    let property: Context.Property

    static func == (lhs: JSONContextPropertyKey<Context>, rhs: JSONContextPropertyKey<Context>) -> Bool {
        lhs.context == rhs.context && lhs.property.rawValue == rhs.property.rawValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(context))
        hasher.combine(property.rawValue)
    }
}
