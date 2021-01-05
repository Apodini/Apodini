import Fluent
import Apodini
@_implementationOnly import Vapor

/// A `Handler` that deletes the object with the given `IDValue` in the database, if it exists. If not an error is thrown.
/// It uses the database that has been specified in the `DatabaseConfiguration`.
public struct Delete<Model: DatabaseModel>: Handler {
    
    @Apodini.Environment(\.database)
    private var database: Fluent.Database

    @Parameter(.http(.path))
    var id: UUID
    
    var idParameter: Parameter<UUID> {
        _id
    }
    
//    public func handle() -> EventLoopFuture<HTTPStatus> {
    public func handle() -> String {
        // swiftlint:disable:next array_init
        Model.find(id, on: database)
            .unwrap(orError: Abort(.notFound))
            .flatMap { $0.delete(on: database )}
            .map { HTTPStatus.ok }
        return String(HTTPStatus.ok.code)
    }
}
