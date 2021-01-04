//
//  Created by Lorena Schlesinger on 03.01.21.
//

import Foundation

func handleUUID(_ node: Node<EnrichedInfo>) throws -> Tree<EnrichedInfo> {
    ParticularType(node.value.typeInfo.type).isUUID
        ? Node(value: node.value, children: [])
        : node
}
