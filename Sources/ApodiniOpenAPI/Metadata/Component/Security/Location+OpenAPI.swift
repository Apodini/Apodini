//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import ApodiniOpenAPISecurity
import OpenAPIKit

extension ApodiniSecurityScheme.Location {
    var openAPIType: OpenAPIKit.OpenAPI.SecurityScheme.Location {
        switch self {
        case .query:
            return .query
        case .cookie:
            return .cookie
        case .header:
            return .header
        }
    }
}
