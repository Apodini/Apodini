//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Fluent

/// A protocol all field property visitors that want to update values of a `FieldProperty` have to conform to.
/// It returns whatever has been specified as `Value`.
protocol UpdatableFieldPropertyVisitor {
    func visit<Model, V>(_ property: inout FieldProperty<Model, V>) throws
}

/// A protocol to make the `FieldProperty` of a database model updatable at run time.
/// It returns `true` if the update of the given `FieldProperty` was successful, else `false`
protocol UpdatableFieldProperty {
    func accept<Visitor: UpdatableFieldPropertyVisitor>(_ visitor: Visitor) throws
}

/// A concrete implementation of the `UpdatableFieldPropertyVisitor` that updates a given `FieldProperty` and returns an `true` if the update was successful
struct ConcreteUpdatableFieldPropertyVisitor: UpdatableFieldPropertyVisitor {
    let updater: TypeContainer
    
    func visit<Model, V>(_ property: inout FieldProperty<Model, V>) throws where Model: Fields, V: Codable {
        if let value = updater.typed() as? V {
            property.value = value
        } else {
            throw DecodingError.typeMismatch(V.self, DecodingError.Context(codingPath: [], debugDescription: "Failed to decode type \(String(describing: updater.typed())) as \(V.self)"))
        }
    }
}

extension FieldProperty: UpdatableFieldProperty {
    func accept<Visitor>(_ visitor: Visitor) throws where Visitor: UpdatableFieldPropertyVisitor {
        var varSelf = self
        return try visitor.visit(&varSelf)
    }
}
