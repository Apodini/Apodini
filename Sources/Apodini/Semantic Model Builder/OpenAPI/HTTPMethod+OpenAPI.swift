//
//  HTTPMethod+OpenAPI.swift
//  
//
//  Created by Lorena Schlesinger on 15.11.20.
//
import Foundation
import Vapor
import OpenAPIKit

/// Extension to map `Vapor.HttpMethod` to `OpenAPI.HttpMethod`.
extension HTTPMethod {
    internal func openAPIHttpMethod() throws -> OpenAPI.HttpMethod {
        switch self {
        case .GET:
            return .get
        case .PUT:
            return .put
        case .POST:
            return .post
        case .DELETE:
            return .delete
        case .OPTIONS:
            return .options
        case .HEAD:
            return .head
        case .PATCH:
            return .patch
        case .TRACE:
            return .trace
        default:
            throw OpenAPIHTTPMethodError.unsupportedHttpMethod(String(describing: self))
        }
    }

    enum OpenAPIHTTPMethodError: Swift.Error {
        case unsupportedHttpMethod(String)
    }
}
