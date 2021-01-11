//
//  Created by Lorena Schlesinger on 15.11.20.
//

import Foundation
@_implementationOnly import OpenAPIKit

extension OpenAPI.HttpMethod {
    init(_ operation: Operation) {
        switch operation {
        case .automatic, .read:
            self = .get
        case .create:
            self = .post
        case .update:
            self = .put
        case .delete:
            self = .delete
        }
    }
}
