//
//  Created by Lorena Schlesinger on 03.01.21.
//

import Foundation
import Apodini

/// Handle the `Foundation.UUID` type.
///
/// `UUID`s storage type is a 16-tuple of `UInt8`. Therefore, its properties are not considered and
/// the type is considererd separaretly.
/// - Parameter node: <#node description#>
/// - Throws: <#description#>
/// - Returns: <#description#>
public func handleUUID(_ node: Node<EnrichedInfo>) throws -> Tree<EnrichedInfo> {
    node.value.typeInfo.type == UUID.self
        ? Node(value: node.value, children: [])
        : node
}
