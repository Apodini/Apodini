//
//  QueryBuilderFilterableProperty.swift
//
//
//  Created by Paul Schmiedmayer on 2/24/21.
//

import Apodini
import Fluent


protocol QueryBuilderFilterableProperty {
    var key: FieldKey { get }
    
    func filterableProperty(withName: String?) -> Apodini.Property
}


extension FieldProperty: QueryBuilderFilterableProperty where Value: QueryBuilderFilterable {
    func filterableProperty(withName name: String?) -> Apodini.Property {
        Apodini.Parameter<Value?>(name ?? self.key.description, .http(.query))
    }
}


extension IDProperty: QueryBuilderFilterableProperty where Value: QueryBuilderFilterable {
    func filterableProperty(withName name: String?) -> Apodini.Property {
        Apodini.Parameter<Value?>(name ?? self.key.description, .http(.query))
    }
}


extension EnumProperty: QueryBuilderFilterableProperty where Value: QueryBuilderFilterable {
    var key: FieldKey {
        field.key
    }
    
    func filterableProperty(withName name: String?) -> Apodini.Property {
        Apodini.Parameter<Value?>(name ?? self.key.description, .http(.query))
    }
}
