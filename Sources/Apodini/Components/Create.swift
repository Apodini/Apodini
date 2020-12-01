//
//  File.swift
//  
//
//  Created by Felix Desiderato on 27.11.20.
//

import Foundation
import Fluent
import Vapor

public class Create<T: DatabaseModel>: Component where T.IDValue == UUID {
    
    @Apodini.Database
    var database: Fluent.Database
    
    @Apodini.Request
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

public class Get<T: DatabaseModel>: Component where T.IDValue: LosslessStringConvertible {
    
    @Apodini.Database
    var database: Fluent.Database
    
    @Apodini.Request
    var request: Vapor.Request
    
    @Param_Id<T>
    var id: T.IDValue
    
    public func handle() -> EventLoopFuture<T> {
        let string = String(format: """
        HTTP/GET
        Request called on: %@
        Id: %@
        """, request.url.string, id.description)
        return T.find(id, on: database).unwrap(or: Abort(.notFound))
    }
    
    public init() {}
}

public class Update<T: DatabaseModel>: Component {
    
    @Apodini.Database
    var database: Fluent.Database
    
    @Apodini.Request
    var request: Vapor.Request
    
    @Apodini.Body
    var object: T
    
    public func handle() -> String {
        let string = String(format: """
        HTTP/POST
        Request called on: %@
        DatabaseModel used: %@
        """, request.url.string, object.description)
        return string
    }
    
    public init() {}
}

public class Delete<T: DatabaseModel>: Component {
    
    @Apodini.Database
    var database: Fluent.Database
    
    @Apodini.Request
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
