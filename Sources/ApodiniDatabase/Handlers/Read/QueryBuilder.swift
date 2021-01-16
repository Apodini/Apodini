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

    internal var parameters: [FieldKey: TypeContainer] = [:]

    init(type: Model.Type, parameters: [FieldKey: TypeContainer]) {
        self.type = type
        self.parameters = parameters
    }
    
    internal func execute(on database: Fluent.Database) -> EventLoopFuture<[Model]> {
        var queryBuilder = Model.query(on: database)
        for (key, value) in parameters {
            queryBuilder.filter(key: key, method: .equal, codableValue: value)
        }
        return queryBuilder.all()
    }
    
    @discardableResult
    internal static func fieldKeys<Model: DatabaseModel>(for type: Model.Type) -> [FieldKey] {
        type.keys
    }
    
    internal static func info(for type: Model.Type) -> [ModelInfo] {
        var modelInfo: [ModelInfo] = []
        let keys = type.keys
        for (index, child) in Mirror(reflecting: Model()).children.enumerated() {
//            print(child)
            let key = keys[index]
            if let idVisitable = child.value as? VisitableIDProperty {
                let concreteCodable = idVisitable.accept(ConcreteIDPropertyVisitor())
                modelInfo.append(ModelInfo(key: key, value: concreteCodable))
//                print(Self.parameter(for: concreteCodable))
//                print(concreteCodable)
            }
            if let fieldVisitable = child.value as? VisitableFieldProperty {
                let concreteCodable = fieldVisitable.accept(ConcreteTypeVisitor())
                modelInfo.append(ModelInfo(key: key, value: concreteCodable))
//                print(Self.parameter(for: concreteCodable))
//                print(concreteCodable)
            }
        }
        return modelInfo
    }
    
    static func parameter<T: Codable>(for: T? = nil) -> Parameter<T?> {
        Parameter<T?>(.http(.query))
    }
}

extension Fluent.QueryBuilder {
    
    func filter(key: FieldKey, method: DatabaseQuery.Filter.Method, codableValue: TypeContainer) {
        switch codableValue {
        case .bool(let value):
            self.filter(key, method, value)
            break
        case .string(let value):
            self.filter(key, method, value)
            break
        case .int(let value):
            self.filter(key, method, value)
            break
        case .int8(let value):
            self.filter(key, method, value)
            break
        case .int16(let value):
            self.filter(key, method, value)
            break
        case .int32(let value):
            self.filter(key, method, value)
            break
        case .int64(let value):
            self.filter(key, method, value)
            break
        case .uint(let value):
            self.filter(key, method, value)
            break
        case .uint8(let value):
            self.filter(key, method, value)
            break
        case .uint16(let value):
            self.filter(key, method, value)
            break
        case .uint32(let value):
            self.filter(key, method, value)
            break
        case .uint64(let value):
            self.filter(key, method, value)
            break
        case .uuid(let value):
            self.filter(key, method, value)
            break
        case .float(let value):
            self.filter(key, method, value)
            break
        case .double(let value):
            self.filter(key, method, value)
            break
        case .noValue:
            break
        }
    }
    
}
