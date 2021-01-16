import Foundation
import Fluent
@_implementationOnly import Vapor
import Apodini

/// A Handler that updates a `DatabaseModel` with the given id with the new object or single parameters of the request.
/// It uses the database that has been specified in the `DatabaseConfiguration`.
public struct Update<Model: DatabaseModel>: Handler {
    @Apodini.Environment(\.database)
    private var database: Fluent.Database
    
    @Parameter<[String: AnyCodable]>
    private var parameters: [String: AnyCodable]
    
    @Parameter
    private var object: Model?
    
    @Parameter(.http(.path))
    var id: Model.IDValue
    
    public func handle() -> EventLoopFuture<Model> {
        let updater = Updater<Model>(parameters, model: object, modelId: id)
        return updater.executeUpdate(on: database)
    }
}
