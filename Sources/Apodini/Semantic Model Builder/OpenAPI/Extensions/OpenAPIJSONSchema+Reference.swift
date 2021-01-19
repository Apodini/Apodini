//
//  Created by Lorena Schlesinger on 15.01.21.
//

@_implementationOnly import OpenAPIKit

extension JSONSchema {
    var isReference: Bool {
        switch self {
        case .reference:
            return true
        case .array(_, let arrayContext):
            return (arrayContext.items)?.isReference ?? false
        case .object(_, let objectContext):
            return (objectContext.additionalProperties?.b)?.isReference ?? false
        default:
            return false
        }
    }
}
