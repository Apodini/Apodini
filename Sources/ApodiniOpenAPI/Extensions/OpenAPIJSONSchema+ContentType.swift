//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import OpenAPIKit

extension JSONSchema {
    /// Currently only `.json` and `.txt` are supported.
    var openAPIContentType: OpenAPIKit.OpenAPI.ContentType {
        switch self {
        case .integer, .string, .number:
            return .txt
        default:
            return .json
        }
    }
}
