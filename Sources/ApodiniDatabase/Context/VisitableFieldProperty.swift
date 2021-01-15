import Fluent

protocol VisitableFieldProperty {
    func accept<Visitor: FieldPropertyVisitor>(_ visitor: Visitor) -> Visitor.Value where Visitor.Value == AnyCodable
}

protocol VisitableIDProperty {
    func accept<Visitor: IDPropertyVisitor>(_ visitor: Visitor) -> Visitor.Value where Visitor.Value == AnyCodable
}

protocol FieldPropertyVisitor where Value: Codable {
    associatedtype Value

    func visit<Model, V>(_ property: FieldProperty<Model, V>) -> Value
    
    static func unwrap<Self>(_ type: Any) -> Self
}

protocol IDPropertyVisitor where Value: Codable {
    associatedtype Value
    
    func visit<Model, V>(_ property: IDProperty<Model, V>) -> Value where Model: DatabaseModel
}

struct ConcreteTypeVisitor: FieldPropertyVisitor {
    typealias Value = AnyCodable
    
    func visit<Model, V>(_ property: FieldProperty<Model, V>) -> Value where Model : Fields, V : Decodable, V : Encodable {
        print(property.value)
        let typeContainer = TypeContainer(with: property.value)
        return AnyCodable(typeContainer)
    }

    static func unwrap<ConcreteTypeVisitor>(_ type: Any) -> ConcreteTypeVisitor {
        return type as! ConcreteTypeVisitor
    }

}

struct ConcreteIDPropertyVisitor: IDPropertyVisitor {
    typealias Value = AnyCodable
    
    func visit<Model, V>(_ property: IDProperty<Model, V>) -> AnyCodable where Model : DatabaseModel, V : Decodable, V : Encodable {
        AnyCodable(property.value)
    }
}

extension FieldProperty: VisitableFieldProperty {

    func accept<Visitor>(_ visitor: Visitor) -> Visitor.Value where Visitor : FieldPropertyVisitor {
        visitor.visit(self)
    }

}

extension IDProperty: VisitableIDProperty where Model: DatabaseModel {
    func accept<Visitor>(_ visitor: Visitor) -> Visitor.Value where Visitor : IDPropertyVisitor {
        visitor.visit(self)
    }
    
}


