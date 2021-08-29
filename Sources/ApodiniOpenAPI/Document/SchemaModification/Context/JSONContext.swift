//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import OpenAPIKit

enum ContextName: String {
    case core
    case numeric
    case integer
    case string
    case object
    case array
}

protocol JSONContext where Self.Property.RawValue == String {
    associatedtype Property: RawRepresentable

    var context: ContextName { get }
}
