import Fluent
import Apodini
@_implementationOnly import Vapor

struct ReadOne<Model: DatabaseModel>: Handler {
    @Throws(.notFound, reason: "No object was found in the database under the given id")
    var objectNotFoundError: ApodiniError
    
    @Apodini.Environment(\.database)
    private var database: Fluent.Database
    
    @Parameter(.http(.path))
    var id: Model.IDValue
    
    func handle() throws -> EventLoopFuture<Model> {
        Model.find(id, on: database).unwrap(orError: objectNotFoundError)
    }
    
    public init() {}
}
