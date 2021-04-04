//
//  Model+Updatable.swift
//
//
//  Created by Paul Schmiedmayer on 2/24/21.
//

import Apodini
import ApodiniUtils
import Fluent


fileprivate protocol ValueContainable {
    var value: Any { get }
}


extension Apodini.Parameter: ValueContainable {
    var value: Any {
        wrappedValue
    }
}


extension Model {
    func updateFields(withProperties properties: [String: Apodini.Property]) {
        let properties = properties.compactMapValues { property in
            property as? ValueContainable
        }
        
        for child in Mirror(reflecting: self).children {
            guard let updatableFieldProperty = child as? UpdatableProperty,
                  let property = properties[updatableFieldProperty.key.description],
                  !isNil(property.value) else {
                continue
            }
            
            updatableFieldProperty.update(withNewValue: property.value)
        }
    }
}
