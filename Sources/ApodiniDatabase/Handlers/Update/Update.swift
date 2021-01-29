import Foundation
import Fluent
@_implementationOnly import Vapor
import Apodini

/// A Handler that updates a `DatabaseModel` with the given id with the new object or single parameters of the request.
/// If the request contains a encoded model, `Update` uses this to replace the model found under the given `ID` in the database.
/// If the request contains a set of parameters, `Update` uses these to update their counterparts
/// in the model found under the given `ID` in the database.
/// It uses the database that has been specified in the `DatabaseConfiguration`.
public struct Update<Model: DatabaseModel>: Handler {
    @Apodini.Environment(\.database)
    private var database: Fluent.Database
    
    @Parameter<[String: TypeContainer]>
    private var parameters: [String: TypeContainer]
    
    @Parameter<Model?>
    private var object: Model?
    
    @Parameter(.http(.path))
    var id: Model.IDValue
    
    public func handle() -> EventLoopFuture<Model> {
        let updater = Updater<Model>(parameters, model: object, modelId: id)
        return updater.executeUpdate(on: database)
    }
}
