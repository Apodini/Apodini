//
//  Created by Lorena Schlesinger on 12.12.20.
//

import OpenAPIKit

extension JSONSchema {
    /// Currently only `.json` and `.txt` are supported.
    var openAPIContentType: OpenAPIKit.OpenAPI.ContentType {
        switch self {
        case .integer, .string, .number:
            return .txt
        default:
            return .json
        }
    }
}
