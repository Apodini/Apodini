//
//  File.swift
//  
//
//  Created by Felix Desiderato on 08.12.20.
//

import Foundation
import Fluent
import Vapor

public struct QueryBuilder<Model: DatabaseModel> {
    
    private let type: Model.Type
    private let queryString: String

    private var fieldKeys: [FieldKey] {
        return type.keys
    }

    private var parameters: [FieldKey: String] {
        var _parameters: [FieldKey: String] = [:]
        let queryParts = queryString.split(separator: "&").map({ String($0) })
        for (index,part) in queryParts.enumerated() {
            let queryParameters = part.split(separator: "=").map({ String($0) })
            guard queryParameters.count == 2 else { fatalError("invalid query") }
            let key = queryParameters[0]
            let value = queryParameters[1]
            guard let fieldKey = fieldKeys.first(where: { $0.description == key }) else { continue }
            _parameters[fieldKey] = value
        }
        return _parameters
    }

    init(type: Model.Type, queryString: String) {
        self.type = type
        self.queryString = queryString
    }
    
    
    public func execute(on database: Fluent.Database) -> EventLoopFuture<[Model]> {
        
        func accumulateFilters(queryBuilder: inout Fluent.QueryBuilder<Model>, key: FieldKey, value: String, method: DatabaseQuery.Filter.Method) {
            if let intValue = Int(value) {
                queryBuilder.filter(key, method, intValue)
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
    public static func fieldKeys<Model: DatabaseModel>(for type: Model.Type) -> [FieldKey] {
        return type.keys
    }
}
