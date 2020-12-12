//
//  Operation+OpenAPI.swift
//  
//
//  Created by Lorena Schlesinger on 15.11.20.
//
import Foundation
import OpenAPIKit

/// Extension to map Apodini `Operation`  to `OpenAPI.HttpMethod`.
extension Operation {
    internal func openAPIHttpMethod() throws -> OpenAPI.HttpMethod {
        switch self {
        case .automatic:
            return .get
        case .read:
            return .get
        case .update:
            return .put
        case .create:
            return .post
        case .delete:
            return .delete
        default:
            throw OpenAPIHTTPMethodError.unsupportedHttpMethod(String(describing: self))
        }
    }

    enum OpenAPIHTTPMethodError: Swift.Error {
        case unsupportedHttpMethod(String)
    }
}
