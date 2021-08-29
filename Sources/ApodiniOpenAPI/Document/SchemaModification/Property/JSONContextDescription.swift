//
// Created by Andreas Bauer on 28.08.21.
//

import Foundation

protocol JSONContextDescription: JSONContextIdentifiable {
    var type: PropertyType.Type { get }
}

struct PropertyDescription<Context: JSONContext, PropertyType>: JSONContextDescription {
    let context: Context.Type
    let property: Context.Property
    let type: PropertyType.Type
}
