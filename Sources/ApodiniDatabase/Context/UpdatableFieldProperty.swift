import Fluent

protocol UpdatableFieldPropertyVisitor where Value: Codable {
    associatedtype Value

    func visit<Model, V>(_ property: inout FieldProperty<Model, V>) -> Value
}

protocol UpdatableFieldProperty {
    func accept<Visitor: UpdatableFieldPropertyVisitor>(_ visitor: Visitor) -> Visitor.Value where Visitor.Value == Bool
}

struct ConcreteUpdatableFieldPropertyVisitor: UpdatableFieldPropertyVisitor {
    typealias Value = Bool
    
    let updater: AnyCodable
    
    func visit<Model, V>(_ property: inout FieldProperty<Model, V>) -> Bool where Model : Fields, V : Decodable, V : Encodable {
        print(property.value)
//        print(updater.wrappedValue)
        print(updater.wrappedType)
        guard let type = updater.wrappedType else { return false }
        if let value = updater.wrappedType?.typed() as? V {
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
