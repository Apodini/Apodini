//
// Created by Andreas Bauer on 28.08.21.
//

import Foundation

struct JSONContextPropertyKey<Context: JSONContext>: Hashable {
    let context: Context.Type
    let property: Context.Property

    func any() -> AnyHashable {
        AnyHashable(self)
    }

    static func == (lhs: JSONContextPropertyKey<Context>, rhs: JSONContextPropertyKey<Context>) -> Bool {
        lhs.context == rhs.context && lhs.property.rawValue == rhs.property.rawValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(context))
        hasher.combine(property.rawValue)
    }
}
