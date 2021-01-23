//
// Created by Andreas Bauer on 22.01.21.
//

@_implementationOnly import Vapor

extension Operation {
    var httpMethod: Vapor.HTTPMethod {
        switch self {
        case .create:
            return .POST
        case .read:
            return .GET
        case .update:
            return .PUT
        case .delete:
            return .DELETE
        }
    }
}
