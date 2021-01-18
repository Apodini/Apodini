//
//  Created by Lorena Schlesinger on 09.12.20.
//

import Foundation
@_implementationOnly import OpenAPIKit

extension OpenAPI.Parameter.Context {
    /// Currently, only `query` and `path` are supported.
    init?(_ endpointParameter: AnyEndpointParameter) {
        switch endpointParameter.parameterType {
        case .lightweight:
            self = .query
        case .path:
            self = .path
        case .content:
            return nil
        }
    }
}
