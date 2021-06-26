//
//  Created by Lorena Schlesinger on 15.11.20.
//

import Foundation
import Apodini
import OpenAPIKit

extension OpenAPIKit.OpenAPI.HttpMethod {
    init(_ operation: Apodini.Operation) {
        switch operation {
        case .read:
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
