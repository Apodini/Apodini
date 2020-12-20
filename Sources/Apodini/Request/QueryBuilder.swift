//
//  File.swift
//  
//
//  Created by Felix Desiderato on 08.12.20.
//

import Foundation
import Fluent
import Vapor
@_implementationOnly import Runtime

public struct QueryBuilder<Model: DatabaseModel> {
    
    private let type: Model.Type
    private var queryString: String? {
        didSet {
            guard let queryString = queryString else { return }
            parameters = extract(from: queryString)
        }
    }

    private var fieldKeys: [FieldKey] {
        return type.keys
    }

    private var parameters: [FieldKey: String] = [:]

    init(type: Model.Type, queryString: String) {
        self.type = type
        self.queryString = queryString
    }
    
    init(type: Model.Type, parameters: [FieldKey: String]) {
        self.type = type
        self.parameters = parameters
    }
    
    private func extract(from queryString: String) -> [FieldKey: String] {
        var _parameters: [FieldKey: String] = [:]
        let queryParts = queryString.split(separator: "&").map({ String($0) })
        for part in queryParts {
            let queryParameters = part.split(separator: "=").map({ String($0) })
            guard queryParameters.count == 2 else { fatalError("invalid query") }
            let key = queryParameters[0]
            let value = queryParameters[1]
            guard let fieldKey = fieldKeys.first(where: { $0.description == key }) else { continue }
            _parameters[fieldKey] = value
        }
        return _parameters
    }
    
    public func execute(on database: Fluent.Database) -> EventLoopFuture<[Model]> {
        
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
        print(queryBuilder)
        return queryBuilder.all()
    }
    
    @discardableResult
    public static func fieldKeys<Model: DatabaseModel>(for type: Model.Type) -> [FieldKey] {
        return type.keys
    }
    
    static func info(for type: Model.Type) -> [ModelInfo] {
        var modelInfo: [ModelInfo] = []
        do {
            
            let keys = type.keys
            let info = try typeInfo(of: type)
            guard info.properties.count == type.keys.count else {
                fatalError("wrong model")
            }
            for (index, propertyInfo) in info.properties.enumerated() {
                if propertyInfo.name.replacingOccurrences(of: "_", with: "") == keys[index].description {
                    let key = keys[index]
                    let type = Self.fieldType(for: propertyInfo.type)
                    modelInfo.append(ModelInfo(key: key, type: type))
                    print(String(describing: propertyInfo.type))
                    print(Self.fieldType(for: propertyInfo.type))
                }
            }
            
            
        } catch {
            fatalError("failed to infer info")
        }
        return modelInfo
    }
    
    //TODO: Find a better way to do this
    private static func fieldType(for type: Any.Type) -> Any.Type {
        let fieldTypeString = String(describing: type)
                .replacingOccurrences(of: "FieldProperty", with: "")
                .replacingOccurrences(of: "<", with: "")
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: ">", with: "").split(separator: ",").map({ String($0) }).last!
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

public struct ModelInfo: DatabaseInjectionContext {
    public var key: FieldKey
    public var type: Any.Type
    
}
