//
//  File.swift
//  
//
//  Created by Felix Desiderato on 08.12.20.
//
import Apodini
import Foundation
import Fluent
@_implementationOnly import Vapor
@_implementationOnly import Runtime

internal struct QueryBuilder<Model: DatabaseModel> {
    internal var debugDescription: String {
        parameters.debugDescription
    }
    
    private let type: Model.Type

    private var fieldKeys: [FieldKey] {
        type.keys
    }

    internal var parameters: [FieldKey: String] = [:]

    init(type: Model.Type, queryString: String) {
        self.type = type
        self.parameters = extract(from: queryString)
    }
    
    init(type: Model.Type, parameters: [FieldKey: String]) {
        self.type = type
        self.parameters = parameters
    }
    
    private func extract(from queryString: String) -> [FieldKey: String] {
        var foundParameters: [FieldKey: String] = [:]
        let extractedQueryString = queryString.split(separator: "?")
        guard extractedQueryString.count >= 2 else {
            return foundParameters
        }
        let queryParts = extractedQueryString[1].split(separator: "&").map { String($0) }
        for part in queryParts {
            let queryParameters = part.split(separator: "=").map { String($0) }
            guard queryParameters.count == 2 else { fatalError("invalid query") }
            let key = queryParameters[0]
            let value = queryParameters[1]
            guard let fieldKey = fieldKeys.first(where: { $0.description == key }) else {
                continue
            }
            foundParameters[fieldKey] = value
        }
        return foundParameters
    }
    
    internal func execute(on database: Fluent.Database) -> EventLoopFuture<[Model]> {
        func accumulateFilters(queryBuilder: inout Fluent.QueryBuilder<Model>, key: FieldKey, value: String, method: DatabaseQuery.Filter.Method) {
            if let intValue = Int(value) {
                queryBuilder.filter(key, method, intValue)
            } else if let boolValue = Bool(value) {
                queryBuilder.filter(key, method, boolValue)
            } else {
                queryBuilder.filter(key, method, value)
            }
        }
        
        var queryBuilder = Model.query(on: database)
        for (key, value) in parameters {
            accumulateFilters(queryBuilder: &queryBuilder, key: key, value: value, method: .equal)
        }
        return queryBuilder.all()
    }
    
    @discardableResult
    internal static func fieldKeys<Model: DatabaseModel>(for type: Model.Type) -> [FieldKey] {
        type.keys
    }
    
    internal static func info(for type: Model.Type) -> [ModelInfo] {
        var modelInfo: [ModelInfo] = []
        do {
            let keys = type.keys
            let info = try typeInfo(of: type)
            for child in Mirror(reflecting: Model()).children {
                print(child)
                if let visitable = child.value as? VisitableFieldProperty {
                    let test = visitable.accept(GenericTypeVisitor())
                    print(test)
                }
            }
            guard info.properties.count == type.keys.count else {
                fatalError("wrong model")
            }
            for (index, propertyInfo) in info.properties.enumerated() {
                if propertyInfo.name.replacingOccurrences(of: "_", with: "") == keys[index].description {
                    let key = keys[index]
                    if let test = propertyInfo.type as? VisitableFieldProperty {
                        print("mnice")
                    }
                    let type = Self.fieldType(for: propertyInfo.type)
                    modelInfo.append(ModelInfo(key: key, type: type))
                }
            }
        } catch {
            fatalError("failed to infer info")
        }
        return modelInfo
    }
    
    // swiftlint:disable:next todo
    //TODO: Find a better way to do this
    private static func fieldType(for type: Any.Type) -> Any.Type {
        guard let fieldTypeString = String(describing: type)
                .replacingOccurrences(of: "FieldProperty", with: "")
                .replacingOccurrences(of: "<", with: "")
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: ">", with: "")
                .split(separator: ",")
                .map({ String($0) })
                .last else {
            return String.self
        }
        switch fieldTypeString {
        case "String":
            return String.self
        case "Int":
            return Int.self
        case "Bool":
            return Bool.self
        case "UUID":
            return UUID.self
        default:
            fatalError("Should not happen")
        }
    }
}


protocol FieldPropertyVisitor where Value: Codable {
    associatedtype Value

    func visit<Model, V>(_ property: FieldProperty<Model, V>) -> Value
    
    static func unwrap<Self>(_ type: Any) -> Self
}

struct ConcreteTypeVisitor: FieldPropertyVisitor {
    typealias Value = AnyCodable

    func visit<Model, V>(_ property: FieldProperty<Model, V>) -> AnyCodable where Model : Fields, V : Decodable, V : Encodable {
        return AnyCodable(property.value)
    }

    static func unwrap<ConcreteTypeVisitor>(_ type: Any) -> ConcreteTypeVisitor {
        return type as! ConcreteTypeVisitor
    }
//    typealias Value = AnyCodable
//
//    func visit<Model, V>(_ property: FieldProperty<Model, V>) -> Value where Model : Fields, V : Decodable, V : Encodable {
//        AnyCodable(property.value)
//    }


}

struct GenericTypeVisitor: FieldPropertyVisitor {
    typealias Value = AnyGenericCodable

    func visit<Model, V>(_ property: FieldProperty<Model, V>) -> Value where Model : Fields, V : Decodable, V : Encodable {
        return AnyGenericCodable(V.self)
    }

    static func unwrap<ConcreteTypeVisitor>(_ type: Any) -> ConcreteTypeVisitor {
        return type as! ConcreteTypeVisitor
    }
//    typealias Value = AnyCodable
//
//    func visit<Model, V>(_ property: FieldProperty<Model, V>) -> Value where Model : Fields, V : Decodable, V : Encodable {
//        AnyCodable(property.value)
//    }


}



protocol VisitableFieldProperty {
    
    func accept<Visitor: FieldPropertyVisitor>(_ visitor: Visitor) -> Visitor.Value where Visitor.Value == AnyCodable
    func accept<Visitor: FieldPropertyVisitor>(_ visitor: Visitor) -> Visitor.Value where Visitor.Value == AnyGenericCodable
}

extension FieldProperty: VisitableFieldProperty {

    func accept<Visitor>(_ visitor: Visitor) -> Visitor.Value where Visitor : FieldPropertyVisitor {
        visitor.visit(self)
    }

}



struct AnyGenericCodable: Codable {
    
    var wrappedValue: Codable.Type?
    
    init(_ wrappedValue: Codable.Type? = nil) {
        self.wrappedValue = wrappedValue
    }
    
    func encode(to encoder: Encoder) throws {
//        wrappedValue?.encode(to: encoder)
    }
    
    init(from decoder: Decoder) throws {
        self.init()
    }
    
}
