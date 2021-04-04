//
//  QueryBuilderFilterableParameter.swift
//
//
//  Created by Paul Schmiedmayer on 2/24/21.
//

import Apodini
import ApodiniUtils
import Fluent


typealias QueryBuilderFilterable = LosslessStringConvertible & Codable


fileprivate protocol QueryBuilderFilterableParameter {
    func filter<M: Model>(
        for model: M.Type,
        on queryBuilder: QueryBuilder<M>,
        key: FieldKey,
        method: DatabaseQuery.Filter.Method
    ) -> QueryBuilder<M>
}

extension Apodini.Parameter: QueryBuilderFilterableParameter where Element: Codable {
    fileprivate func filter<M: Model>(
        for model: M.Type,
        on queryBuilder: QueryBuilder<M>,
        key: FieldKey,
        method: DatabaseQuery.Filter.Method
    ) -> QueryBuilder<M> {
        if isNil(wrappedValue) {
            return queryBuilder
        }
        
        return queryBuilder.filter(key, method, wrappedValue)
    }
}


extension QueryBuilder {
    func filter(basedOn properties: [String: Apodini.Property]) -> QueryBuilder<Model> {
        let properties = properties.compactMapValues { property in
            property as? QueryBuilderFilterableParameter
        }
        
        return Model.filterableFieldKeyProperties
            .map(\.key)
            .reduce(self) { queryBuilder, fieldKey in
                guard let property = properties[fieldKey.description] else {
                    return queryBuilder
                }

                return property.filter(for: Model.self, on: queryBuilder, key: fieldKey, method: .equal)
            }
    }
}
