//
//  EndpointParameter+OpenAPI.swift
//  
//
//  Created by Lorena Schlesinger on 09.12.20.
//

import Foundation
import OpenAPIKit

/// Extension to map Apodini `Operation`  to `OpenAPI.HttpMethod`.
extension EndpointParameter {
    func openAPIContext() -> OpenAPI.Parameter.Context? {
        switch self.parameterType {
        case .lightweight:
            return OpenAPI.Parameter.Context.query
        case .path:
            return OpenAPI.Parameter.Context.path
        case .content:
            return nil
        }
    }
}
