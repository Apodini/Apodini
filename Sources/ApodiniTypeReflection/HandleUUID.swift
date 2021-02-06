//
//  Created by Lorena Schlesinger on 03.01.21.
//

import Foundation
import Apodini

/// Handle the `Foundation.UUID` type.
///
/// `UUID`s storage type is a 16-tuple of `UInt8`. Therefore, its properties are not considered and
/// the type is handled separaretly.
/// - Parameter node: An `ReflectionInfo` node.
/// - Returns: An `ReflectionInfo` node.
public func handleUUID(_ node: Node<ReflectionInfo>) -> Node<ReflectionInfo> {
    node.value.typeInfo.type == UUID.self
        ? Node(value: node.value, children: [])
        : node
}
