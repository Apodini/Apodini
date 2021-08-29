//
// Created by Andreas Bauer on 28.08.21.
//

import Foundation

public protocol AnyJSONContextModification {
    var anyValue: Any { get }

    var anyKey: AnyHashable { get }
}


protocol JSONContextModification: JSONContextIdentifiable, AnyJSONContextModification {
    var value: PropertyType { get }
}

extension JSONContextModification {
    var anyValue: Any {
        value
    }
}


struct PropertyModification<Context: JSONContext, PropertyType>: JSONContextModification {
    let context: Context.Type
    let property: Context.Property
    let value: PropertyType
}
