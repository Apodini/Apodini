//
//  Created by Lorena Schlesinger on 28.11.20.
//

@_implementationOnly import OpenAPIKit
@_implementationOnly import Runtime
import Foundation

extension TypeInfo {

    var openAPIJSONSchema: JSONSchema {
        switch type {
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
        case is UUID.Type:
            return .string
        default:
            print("OpenAPI schema not found for type \(type).")
            return .object
        }
    }
}
