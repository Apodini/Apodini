//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

protocol JSONContextIdentifiable {
    associatedtype Context: JSONContext
    associatedtype PropertyType

    var context: Context.Type { get }
    var property: Context.Property { get }

    var key: JSONContextPropertyKey<Context> { get }
}

extension JSONContextIdentifiable {
    var key: JSONContextPropertyKey<Context> {
        JSONContextPropertyKey(context: context, property: property)
    }

    var anyKey: AnyHashable {
        AnyHashable(key)
    }
}
