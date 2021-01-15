//
//  Created by Lorena Schlesinger on 15.01.21.
//

@_implementationOnly import OpenAPIKit

extension JSONSchema {
    var isReference: Bool {
        switch self {
        case .reference(let ref):
            return true
        case .array:
            guard let schema = arrayContext?.items else {
                return false
            }
            return schema.isReference
        default:
            return false
        }
    }
}
