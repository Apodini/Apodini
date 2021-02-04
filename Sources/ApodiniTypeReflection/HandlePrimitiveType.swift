//
//  Created by Nityananda on 12.12.20.
//

import Apodini
// swiftlint:disable missing_docs

public func handlePrimitiveType(_ node: Node<EnrichedInfo>) throws -> Tree<EnrichedInfo> {
    isSupportedScalarType(node.value.typeInfo.type)
        ? Node(value: node.value, children: [])
        : node
}
