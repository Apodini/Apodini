//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

/// Type erased version of the `OpenAPIKit.OpenAPI.SecurityScheme.SchemeType` type.
public protocol OpenAPISecurityType {
    /// Maps the generalized Apodini ``ApodiniSecurityType.SchemeType`` to the OpenAPIKit one.
    /// Mapping happens in the context of a dedicated endpoint (e.g. to considered declared parameters).
    static func mapType<H: Handler>(from type: ApodiniSecurityType.SchemeType, on endpoint: Endpoint<H>) -> Self
}
