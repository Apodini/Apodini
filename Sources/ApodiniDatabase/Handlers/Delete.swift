import Fluent
import Apodini
@_implementationOnly import Vapor

/// A `Handler` that deletes the object with the given `IDValue` in the database, if it exists. If not an error is thrown.
/// It uses the database that has been specified in the `DatabaseConfiguration`.
public struct Delete<Model: DatabaseModel>: Handler {
    @Apodini.Environment(\.database)
    private var database: Fluent.Database

    @Parameter(.http(.path))
    var id: Model.IDValue
    
    public func handle() -> EventLoopFuture<UInt> {
        Model.find(id, on: database)
            .unwrap(orError: Abort(.notFound) )
            .flatMap { $0.delete(on: database ) }
            .transform(to: HTTPStatus.ok.code )
    }
    
    public init() {}
}
