//
// Created by Andreas Bauer on 28.08.21.
//

import Foundation

protocol JSONContextIdentifiable {
    associatedtype Context: JSONContext
    associatedtype PropertyType

    var context: Context.Type { get }
    var property: Context.Property { get }

    var key: JSONContextPropertyKey<Context> { get }
}

extension JSONContextIdentifiable {
    var key: JSONContextPropertyKey<Context> {
        JSONContextPropertyKey(context: context, property: property)
    }

    var anyKey: AnyHashable {
        AnyHashable(key)
    }
}
