//
//  Created by Lorena Schlesinger on 09.12.20.
//

import Foundation
import Apodini
import OpenAPIKit

extension OpenAPI.Parameter.Context {
    /// Currently, only `query` and `path` are supported.
    init?(_ endpointParameter: AnyEndpointParameter) {
        switch endpointParameter.parameterType {
        case .lightweight:
                self = .query(required: !endpointParameter.nilIsValidValue && endpointParameter.option(for: PropertyOptionKey.optionality) != Optionality.optional)
        case .path:
            self = .path
        case .content, .header:
            return nil
        }
    }
}
