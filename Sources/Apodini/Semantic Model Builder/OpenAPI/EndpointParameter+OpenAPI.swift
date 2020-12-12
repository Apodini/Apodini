//
//  EndpointParameter+OpenAPI.swift
//  
//
//  Created by Lorena Schlesinger on 09.12.20.
//

import Foundation
import OpenAPIKit

/// Extension to map Apodini `EndpointParameter.EndpointParameterType` to `OpenAPI.Parameter.Context`.
/// Currently, only `query` and `path` are supported.
extension EndpointParameter {
    func openAPIContext() -> OpenAPI.Parameter.Context? {
        switch self.parameterType {
        case .lightweight:
            return .query
        case .path:
            return .path
        case .content:
            return nil
        }
    }

    func openAPISchema() -> JSONSchema {
        switch self.contentType {
        case is Int.Type:
            return .integer
        case is Bool.Type:
            return .boolean
        case is String.Type:
            return .string
        case is Double.Type:
            return .number(format: .double)
        case is Date.Type:
            return .string(format: .date)
        default:
            return .string
        }
    }
}
