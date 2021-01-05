import Fluent
import Apodini

/// A Handler that creates, if possible, an object in the database that conforms to `DatabaseModel` out of the body of the request.
/// It uses the database that has been specified in the `DatabaseConfiguration`.
public struct Create<T: DatabaseModel>: Handler {
    
    @Apodini.Environment(\.database)
    private var database: Fluent.Database
    
    @Parameter
    private var object: T

    public func handle() -> T? {
        let result = try! object.save(on: database).map({ _ in
            self.object
        }).wait()
        return try! T.find(result.id, on: database).map({ object in
            object
        }).wait()
    }
}
