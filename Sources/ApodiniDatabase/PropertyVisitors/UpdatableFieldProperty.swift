import Fluent

/// A protocol all field property visitors that want to update values of a `FieldProperty` have to conform to.
/// It returns whatever has been specified as `Value`.
protocol UpdatableFieldPropertyVisitor where Value: Codable {
    associatedtype Value

    func visit<Model, V>(_ property: inout FieldProperty<Model, V>) -> Value
}

/// A protocol to make the `FieldProperty` of a database model updatable at run time.
/// It returns `true` if the update of the given `FieldProperty` was successful, else `false`
protocol UpdatableFieldProperty {
    func accept<Visitor: UpdatableFieldPropertyVisitor>(_ visitor: Visitor) -> Visitor.Value where Visitor.Value == Bool
}

/// A concrete implementation of the `UpdatableFieldPropertyVisitor` that updates a given `FieldProperty` and returns an `true` if the update was successful
struct ConcreteUpdatableFieldPropertyVisitor: UpdatableFieldPropertyVisitor {
    typealias Value = Bool
    
    let updater: TypeContainer
    
    func visit<Model, V>(_ property: inout FieldProperty<Model, V>) -> Bool where Model: Fields, V: Decodable, V: Encodable {
        if let value = updater.typed() as? V {
            property.value = value
            return true
        }
        return false
    }
}

extension FieldProperty: UpdatableFieldProperty {
    func accept<Visitor>(_ visitor: Visitor) -> Visitor.Value where Visitor : UpdatableFieldPropertyVisitor, Visitor.Value == Bool {
        var varSelf = self
        return visitor.visit(&varSelf)
    }
}
