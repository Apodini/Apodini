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
        let queryBuilder = Apodini.QueryBuilder(type: T.self, queryString: queryString)
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



