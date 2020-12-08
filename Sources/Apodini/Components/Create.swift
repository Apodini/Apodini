//
//  File.swift
//  
//
//  Created by Felix Desiderato on 27.11.20.
//

import Foundation
import Fluent
import Vapor

public struct Create<T: DatabaseModel>: Component where T.IDValue == UUID {
    
    @_Database
    var database: Fluent.Database
    
    @_Request
    var request: Vapor.Request
    
    @Apodini.Body
    var object: T

    public func handle() -> EventLoopFuture<T> {
        let string = String(format: """
        HTTP/POST
        Request called on: %@
        DatabaseModel used: %@
        """, request.url.string, object.description)
        return object.save(on: database).map({ _ in
            self.object
        })
    }
    
    public init() {}
}

public struct Get<T: DatabaseModel>: Component where T.IDValue: LosslessStringConvertible {
    
    @_Database
    var database: Fluent.Database
    
    @_Request
    var request: Vapor.Request
    
//    @Parameter var id: T.IDValue
//    @Param_Id<T>
//    var id: T.IDValue
    
    @_Query
    var queryString: String
    
    public func handle() -> EventLoopFuture<[T]> {
        let queryBuilder = MyQueryBuilder(type: T.self, queryString: queryString)
        return queryBuilder.execute(on: database)
    }
    public init() {}
}

public struct Update<T: DatabaseModel>: Component where T.IDValue: LosslessStringConvertible {
    
    @_Database
    var database: Fluent.Database
    
    @_Request
    var request: Vapor.Request
    
    @Apodini.Body
    var object: T
    
    @Param_Id<T>
    var id: T.IDValue
    
    public func handle() -> EventLoopFuture<T> {
        let string = String(format: """
        HTTP/POST
        Request called on: %@
        DatabaseModel used: %@
        """, request.url.string, object.description)
        T.query(on: database).filter(\., <#T##method: DatabaseQuery.Filter.Method##DatabaseQuery.Filter.Method#>, <#T##value: Decodable & Encodable##Decodable & Encodable#>)
        return T.find(id, on: database).flatMapThrowing({ model -> T in
            model?.update(object)
            return model!
        }).flatMap({ model in
            model.update(on: database).map({ model })
        })
    }
    
    public init() {}
}

public struct Delete<T: DatabaseModel>: Component {
    
    @_Database
    var database: Fluent.Database
    
    @_Request
    var request: Vapor.Request
    
    @Apodini.Body
    var object: T
    
    public func handle() -> String {
        let string = String(format: """
        HTTP/DELETE
        Request called on: %@
        DatabaseModel used: %@
        """, request.url.string, object.description)
        return string
    }
    
    public init() {}
}

public struct MyQueryBuilder<Model: DatabaseModel> {
    
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
        
        func accumulateFilters(queryBuilder: inout QueryBuilder<Model>, key: FieldKey, value: String, method: DatabaseQuery.Filter.Method) {
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

