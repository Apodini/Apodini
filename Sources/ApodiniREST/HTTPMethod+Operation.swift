//
// Created by Andreas Bauer on 22.01.21.
//

@_implementationOnly import Vapor

extension Vapor.HTTPMethod {
    init(_ operation: Operation) {
        switch operation {
        case .create:
            self =  .POST
        case .read:
            self =  .GET
        case .update:
            self =  .PUT
        case .delete:
            self =  .DELETE
        }
    }
}
