import Fluent
import Apodini
@_implementationOnly import Vapor

/// A `Handler` that deletes the object with the given `IDValue` in the database, if it exists. If not an error is thrown.
/// It uses the database that has been specified in the `DatabaseConfiguration`.
public struct Delete<T: DatabaseModel>: Handler {
    
    @Apodini.Environment(\.database)
    private var database: Fluent.Database

    @Parameter
    private var id: T.IDValue
    
//    public func handle() -> EventLoopFuture<HTTPStatus> {
    public func handle() -> String {
        T.find(id, on: database)
            .unwrap(orError: Abort(.notFound))
            .flatMap({ $0.delete(on: database )})
            .map({ HTTPStatus.ok })
        return "ok"
    }
}
