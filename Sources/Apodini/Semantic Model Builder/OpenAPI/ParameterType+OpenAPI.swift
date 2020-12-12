//
//  File.swift
//  
//
//  Created by Lorena Schlesinger on 09.12.20.
//

import Foundation
import OpenAPIKit

/// Extension to map Apodini `Operation`  to `OpenAPI.HttpMethod`.
extension EndpointParameter {
    internal func openAPIContext() throws -> OpenAPI.Parameter.Context {
        switch self.parameterType {
        case .lightweight:
            return OpenAPI.Parameter.Context.query
        case .path:
            return OpenAPI.Parameter.Context.path
        default:
            // TODO
            throw OpenAPIHTTPMethodError.unsupportedHttpMethod(String(describing: self))
        }
    }

    enum OpenAPIHTTPMethodError: Swift.Error {
        case unsupportedHttpMethod(String)
    }
}
