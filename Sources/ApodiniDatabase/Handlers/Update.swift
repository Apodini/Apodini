import Foundation
import Fluent
@_implementationOnly import Vapor
import Apodini

/// A Handler that updates a `DatabaseModel` with the given id with the new object of the request.
/// It uses the database that has been specified in the `DatabaseConfiguration`.
public struct Update<Model: DatabaseModel>: Handler {
    @Apodini.Environment(\.database)
    private var database: Fluent.Database
    
    @Parameter
    private var object: Model
    
    @Parameter(.http(.path))
    var id: UUID
    
    var idParameter: Parameter<UUID> {
        _id
    }
    
//    public func handle() -> EventLoopFuture<T> {
    public func handle() -> String {
        // swiftlint:disable all
        Model.find(id, on: database)
            .unwrap(orError: Abort(.notFound))
            .map { model -> Model in
                print(model)
                model.update(object)
                model.update(on: database)
            
                return model
            }
        return "success"
        // swiftlint:enable all
    }
}
