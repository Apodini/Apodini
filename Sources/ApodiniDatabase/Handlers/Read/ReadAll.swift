//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import FluentKit
import Apodini

/// A Handler that returns an array of `DatabaseModel` which all conform to the query parameters of the request.
/// It accepts all parameters that represent properties of the specified `DatabaseModel`.
/// It uses the database that has been specified in the `DatabaseConfiguration`.
/// An Example using a REST request:
/// Group("api", "birds") {
///     ReadAll<Bird>()
/// }
/// Sending a request to  ~/api/birds/birds?age=19&name=Foo would 
/// return an array of `Bird` objects that have an age of 19 and the name Foo.
public struct ReadAll<Model: DatabaseModel>: Handler {
    @Apodini.Environment(\.database)
    private var database: FluentKit.Database

    @Properties
    private var dynamics: [String: Apodini.Property]
    
    public init() {
        var dynamicValues: [String: Parameter<TypeContainer?>] = [:]
        let infos = QueryBuilder.info(for: Model.self)
        for info in infos {
            dynamicValues[info.key.description] = QueryBuilder<Model>.parameter(info.value)
        }
        _dynamics = Properties(wrappedValue: dynamicValues)
    }

    public func handle() -> EventLoopFuture<[Model]> {
        let queryInfo: [FieldKey: TypeContainer] = _dynamics.typed(Parameter<TypeContainer?>.self)
            .reduce(into: [FieldKey: TypeContainer]()) { result, entry in
                result[Model.fieldKey(for: entry.0)] = entry.1.wrappedValue
            }
            .compactMapValues { $0 }
            .filter { _, value in value != .noValue }
        // if no query dict is empty, return all items
        guard !queryInfo.isEmpty else {
            return Model.query(on: database).all()
        }
        let queryBuilder = QueryBuilder(type: Model.self, parameters: queryInfo)
        return queryBuilder.execute(on: database)
    }
    
    public var metadata: AnyHandlerMetadata {
        Operation(.read)
    }
}
