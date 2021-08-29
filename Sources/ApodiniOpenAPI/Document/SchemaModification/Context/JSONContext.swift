//
// Created by Andreas Bauer on 28.08.21.
//

import Foundation
import OpenAPIKit

enum ContextName: String {
    case core
    case numeric
    case integer
    case string
    case object
    case array
}

protocol JSONContext where Self.Property.RawValue == String {
    associatedtype Property: RawRepresentable

    var context: ContextName { get }
}
