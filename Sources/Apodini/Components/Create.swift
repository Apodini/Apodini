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
    
    @_Request
    var request: Vapor.Request
    
    @_Database
    var database: Fluent.Database
    
    @Parameter
    var object: T

    public func handle() -> EventLoopFuture<T> {
        return object.save(on: database).map({ _ in
            self.object
        })
    }
    
    public init() {}
}



public struct Update<T: DatabaseModel>: Component where T.IDValue: LosslessStringConvertible {
    
    @_Database
    var database: Fluent.Database
    
    @Parameter var object: T
    
    @Parameter var id: T.IDValue
    
    public func handle() -> EventLoopFuture<T> {
        return T.find(id, on: database).flatMapThrowing({ model -> T in
            model?.update(object)
            return model!
        }).flatMap({ model in
            model.update(on: database).map({ model })
        })
    }
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



