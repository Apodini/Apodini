//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

protocol JSONContextDescription: JSONContextIdentifiable {
    var type: PropertyType.Type { get }
}

struct PropertyDescription<Context: JSONContext, PropertyType>: JSONContextDescription {
    let context: Context.Type
    let property: Context.Property
    let type: PropertyType.Type
}
