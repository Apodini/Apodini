//
//  Created by Lorena Schlesinger on 03.01.21.
//

import Foundation
import Apodini

// swiftlint:disable missing_docs

public func handleUUID(_ node: Node<EnrichedInfo>) throws -> Tree<EnrichedInfo> {
    node.value.typeInfo.type == UUID.self
        ? Node(value: node.value, children: [])
        : node
}
