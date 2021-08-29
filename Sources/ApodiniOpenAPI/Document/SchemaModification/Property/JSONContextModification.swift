//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// Represents any modification to the OpenAPIKit json context.
public protocol AnyJSONContextModification {
    /// The type erased value to which the context property should be modified.
    var anyValue: Any { get }

    /// The type erased `JSONContextPropertyKey` which identifies this modification.
    var anyKey: AnyHashable { get }
}


protocol JSONContextModification: JSONContextIdentifiable, AnyJSONContextModification {
    var value: PropertyType { get }
}

extension JSONContextModification {
    var anyValue: Any {
        value
    }
}


struct PropertyModification<Context: JSONContext, PropertyType>: JSONContextModification {
    let context: Context.Type
    let property: Context.Property
    let value: PropertyType
}
