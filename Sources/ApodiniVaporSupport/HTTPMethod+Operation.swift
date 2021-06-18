//
// Created by Andreas Bauer on 22.01.21.
//

import Apodini
import Vapor


extension Vapor.HTTPMethod {
    /// Creates a `Vapor``HTTPMethod` based on an `Apodini` `Operation`.
    /// - Parameter operation: The `Apodini` `Operation` that should be transformed in a `Vapor``HTTPMethod`
    public init(_ operation: Apodini.Operation) {
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
