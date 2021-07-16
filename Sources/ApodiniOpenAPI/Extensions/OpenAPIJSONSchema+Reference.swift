//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import OpenAPIKit

extension JSONSchema {
    var isReference: Bool {
        switch self {
        case .reference:
            return true
        case .array(_, let arrayContext):
            return (arrayContext.items)?.isReference ?? false
        case .object(_, let objectContext):
            return (objectContext.additionalProperties?.b)?.isReference ?? false
        default:
            return false
        }
    }
}
