import Foundation
import Fluent
import Vapor

public struct Delete<T: DatabaseModel>: Component {
    
    @_Database
    var database: Fluent.Database

    @Parameter
    var id: T.IDValue
    
    public func handle() -> EventLoopFuture<HTTPStatus> {
        return T.find(id, on: database)
            .unwrap(orError: Abort(.notFound))
            .flatMap({ $0.delete(on: database )})
            .map({ .ok })
    }
}
