import Foundation
import Fluent
@_implementationOnly import Vapor

public struct Update<T: DatabaseModel>: Handler where T.IDValue: LosslessStringConvertible {
    
    @Apodini.Environment(\.database)
    var database: Fluent.Database
    
    @Parameter var object: T
    
    @Parameter var id: T.IDValue
    
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
