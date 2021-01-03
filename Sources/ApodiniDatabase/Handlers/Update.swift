import Foundation
import Fluent
@_implementationOnly import Vapor
import Apodini

/// A Handler that updates a `DatabaseModel` with the given id with the new object of the request.
/// It uses the database that has been specified in the `DatabaseConfiguration`.
public struct Update<T: DatabaseModel>: Handler where T.IDValue: LosslessStringConvertible {
    
    @Apodini.Environment(\.database)
    private var database: Fluent.Database
    
    @Parameter
    private var object: T
    
    @Parameter
    private var id: T.IDValue
    
//    public func handle() -> EventLoopFuture<T> {
    public func handle() -> String {
        T.find(id, on: database).flatMapThrowing({ model -> T? in
            model?.update(object)
            return model
        }).unwrap(orError: Abort(.notFound)).flatMap({ model in
            model.update(on: database).map({ model })
        })
        return "success"
        
    }
}
