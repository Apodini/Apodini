import Fluent

/// A protocol to make the `FieldProperty` of a database model accessible at run time.
/// It returns an `AnyCodable` object which contains the value associated with this `FieldProperty`
protocol VisitableFieldProperty {
    func accept<Visitor: FieldPropertyVisitor>(_ visitor: Visitor) -> Visitor.Value where Visitor.Value == TypeContainer
}

/// A protocol to make the `FieldProperty` of a database model accessible at run time.
/// It returns an `AnyCodable` object which contains the value associated with this `IDProperty`
protocol VisitableIDProperty {
    func accept<Visitor: IDPropertyVisitor>(_ visitor: Visitor) -> Visitor.Value where Visitor.Value == TypeContainer
}

/// A protocol all field property visitors have to conform to. It returns whatever has been specified as `Value`.
protocol FieldPropertyVisitor where Value: Codable {
    associatedtype Value

    func visit<Model, V>(_ property: FieldProperty<Model, V>) -> Value
}

/// A protocol all id property visitors have to conform to. It returns whatever has been specified as `Value`.
protocol IDPropertyVisitor where Value: Codable {
    associatedtype Value
    
    func visit<Model, V>(_ property: IDProperty<Model, V>) -> Value where Model: DatabaseModel
}

/// A concrete implementation of the `FieldPropertyVisitor` that visits a given `FieldProperty` and returns an `AnyCodable` object
struct ConcreteTypeVisitor: FieldPropertyVisitor {
    typealias Value = TypeContainer
    
    func visit<Model, V>(_ property: FieldProperty<Model, V>) -> Value where Model: Fields, V: Decodable, V: Encodable {
        TypeContainer(with: property.value)
    }
}

/// A concrete implementation of the `IDPropertyVisitor` that visits a given `IDProperty` and returns an `AnyCodable` object
struct ConcreteIDPropertyVisitor: IDPropertyVisitor {
    typealias Value = TypeContainer
    
    func visit<Model, V>(_ property: IDProperty<Model, V>) -> TypeContainer where Model: DatabaseModel, V: Decodable, V: Encodable {
        TypeContainer(with: property.value)
    }
}

extension FieldProperty: VisitableFieldProperty {
    func accept<Visitor>(_ visitor: Visitor) -> Visitor.Value where Visitor: FieldPropertyVisitor {
        visitor.visit(self)
    }
}

extension IDProperty: VisitableIDProperty where Model: DatabaseModel {
    func accept<Visitor>(_ visitor: Visitor) -> Visitor.Value where Visitor: IDPropertyVisitor {
        visitor.visit(self)
    }
}
