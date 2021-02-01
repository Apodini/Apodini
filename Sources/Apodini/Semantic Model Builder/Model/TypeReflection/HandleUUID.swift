//
//  Created by Lorena Schlesinger on 03.01.21.
//

import Foundation

public func handleUUID(_ node: Node<EnrichedInfo>) throws -> Tree<EnrichedInfo> {
    node.value.typeInfo.type == UUID.self
        ? Node(value: node.value, children: [])
        : node
}
