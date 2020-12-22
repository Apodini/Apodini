import Foundation
import Fluent
import Vapor

public struct Update<T: DatabaseModel>: Component where T.IDValue: LosslessStringConvertible {
    
    @_Database
    var database: Fluent.Database
    
    @Parameter var object: T
    
    @Parameter var id: T.IDValue
    
    public func handle() -> EventLoopFuture<T> {
        return T.find(id, on: database).flatMapThrowing({ model -> T? in
            model?.update(object)
            return model
        }).unwrap(orError: Abort(.notFound)).flatMap({ model in
            model.update(on: database).map({ model })
        })
    }
}
