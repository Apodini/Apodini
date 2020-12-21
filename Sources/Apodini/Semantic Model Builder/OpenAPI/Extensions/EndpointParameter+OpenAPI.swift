//
//  Created by Lorena Schlesinger on 09.12.20.
//

import Foundation
@_implementationOnly import OpenAPIKit

extension EndpointParameter {
    /// Currently, only `query` and `path` are supported.
    var openAPIContext: OpenAPI.Parameter.Context? {
        switch self.parameterType {
        case .lightweight:
            return .query
        case .path:
            return .path
        case .content:
            return nil
        }
    }

    var openAPISchema: JSONSchema {
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
