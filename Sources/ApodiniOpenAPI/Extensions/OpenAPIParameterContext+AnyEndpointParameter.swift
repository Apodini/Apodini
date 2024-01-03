//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Apodini
import OpenAPIKit

extension OpenAPIKit.OpenAPI.Parameter.Context {
    /// Currently, only `query` and `path` are supported.
    init?(_ endpointParameter: any AnyEndpointParameter) {
        switch endpointParameter.parameterType {
        case .lightweight:
            self = .query(required: Self.isRequired(endpointParameter))
        case .path:
            self = .path
        case .content:
            return nil
        }
    }
    
    private static func isRequired(_ endpointParameter: any AnyEndpointParameter) -> Bool {
        !endpointParameter.nilIsValidValue
            && !endpointParameter.hasDefaultValue
            && endpointParameter.option(for: PropertyOptionKey.optionality) != Optionality.optional
    }
}
