import Fluent
import Apodini
@_implementationOnly import Vapor

public struct Delete<T: Apodini.DatabaseModel>: Handler {
    
    @Apodini.Environment(\.database)
    var database: Fluent.Database

    @Parameter
    var id: T.IDValue
    
//    public func handle() -> EventLoopFuture<HTTPStatus> {
    public func handle() -> String {
        T.find(id, on: database)
            .unwrap(orError: Abort(.notFound))
            .flatMap({ $0.delete(on: database )})
            .map({ HTTPStatus.ok })
        return "ok"
    }
}
