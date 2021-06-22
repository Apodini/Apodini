//
//  Created by Lorena Schlesinger on 09.12.20.
//

import Foundation
import Apodini
import OpenAPIKit

extension OpenAPIKit.OpenAPI.Parameter.Context {
    /// Currently, only `query` and `path` are supported.
    init?(_ endpointParameter: AnyEndpointParameter) {
        switch endpointParameter.parameterType {
        case .lightweight:
            self = .query(required: Self.isRequired(endpointParameter))
        case .path:
            self = .path
        case .content:
            return nil
        }
    }
    
    private static func isRequired(_ endpointParameter: AnyEndpointParameter) -> Bool {
        !endpointParameter.nilIsValidValue
            && !endpointParameter.hasDefaultValue
            && endpointParameter.option(for: PropertyOptionKey.optionality) != Optionality.optional
    }
}
