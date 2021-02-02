//
//  Created by Nityananda on 12.12.20.
//

import Apodini

public func handlePrimitiveType(_ node: Node<EnrichedInfo>) throws -> Tree<EnrichedInfo> {
    isSupportedScalarType(node.value.typeInfo.type)
        ? Node(value: node.value, children: [])
        : node
}
