//
//  UpdatableProperty.swift
//  
//
//  Created by Paul Schmiedmayer on 2/24/21.
//

import Apodini


protocol UpdatableProperty {
    var key: FieldKey { get }
    
    func updatableProperty(withName: String?) -> Apodini.Property
    func update(withNewValue: Any)
}


extension FieldProperty: UpdatableProperty {
    func updatableProperty(withName name: String?) -> Apodini.Property {
        Apodini.Parameter<Value?>(name ?? self.key.description, .http(.body))
    }
    
    func update(withNewValue newValue: Any) {
        guard let newValue = newValue as? Value else {
            return
        }
        self.wrappedValue = newValue
    }
}


extension IDProperty: UpdatableProperty {
    func updatableProperty(withName name: String?) -> Apodini.Property {
        Apodini.Parameter<Value?>(name ?? self.key.description, .http(.body))
    }
    
    func update(withNewValue newValue: Any) {
        guard let newValue = newValue as? Value else {
            return
        }
        self.wrappedValue = newValue
    }
}


extension EnumProperty: UpdatableProperty {
    var key: FieldKey {
        field.key
    }
    
    func updatableProperty(withName name: String?) -> Apodini.Property {
        Apodini.Parameter<Value?>(name ?? self.key.description, .http(.body))
    }
    
    func update(withNewValue newValue: Any) {
        guard let newValue = newValue as? Value else {
            return
        }
        self.wrappedValue = newValue
    }
}
