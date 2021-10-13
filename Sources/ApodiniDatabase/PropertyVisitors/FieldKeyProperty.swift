//
//  FieldKeyProperty.swift
//
//
//  Created by Paul Schmiedmayer on 2/24/21.
//

import Apodini
import FluentKit


///A struct implementing `FieldKeyProperty` and containing a fieldkey and the expected type for that key.
struct FieldKeyProperty {
    ///A concrete `FluentKit.FieldKey`
    let key: FieldKey
    ///A concrete type for that fieldkey
    let property: Apodini.Property
    
    
    fileprivate init(_ context: QueryBuilderFilterableProperty, propertyName: String?) {
        key = context.key
        property = context.filterableProperty(withName: propertyName)
    }
    
    fileprivate init(_ context: UpdatableProperty, propertyName: String?) {
        key = context.key
        property = context.updatableProperty(withName: propertyName)
    }
}


private enum ExpectedPropertyType {
    case filterable
    case updatable
}


extension Model {
    static var filterableFieldKeyProperties: [FieldKeyProperty] {
        fieldKeyProperties(type: .filterable)
    }
    
    static var updatableFieldKeyProperties: [FieldKeyProperty] {
        fieldKeyProperties(type: .updatable)
    }
    
    private static func fieldKeyProperties(type: ExpectedPropertyType) -> [FieldKeyProperty] {
        Mirror(reflecting: Self())
            .children
            .compactMap { child in
                guard let name = child.label?.trimmedPropertyWrapperName else {
                    return nil
                }
                
                switch type {
                case .filterable:
                    return (child.value as? QueryBuilderFilterableProperty).map {
                        FieldKeyProperty($0, propertyName: name)
                    }
                case .updatable:
                    return (child.value as? UpdatableProperty).map {
                        FieldKeyProperty($0, propertyName: name)
                    }
                }
            }
    }
}


extension Array where Element == FieldKeyProperty {
    var dynamics: [String: Apodini.Property] {
        Dictionary(uniqueKeysWithValues:
            self.map { fieldKeyProperty in
                    (fieldKeyProperty.key.description, fieldKeyProperty.property)
                }
        )
    }
}
