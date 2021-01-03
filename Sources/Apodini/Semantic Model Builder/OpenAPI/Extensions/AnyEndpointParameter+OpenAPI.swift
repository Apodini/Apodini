//
//  Created by Lorena Schlesinger on 09.12.20.
//

import Foundation
@_implementationOnly import OpenAPIKit

extension AnyEndpointParameter {
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
}