import Fluent
import Apodini

/// A Handler that creates, if possible, an object in the database that conforms to `DatabaseModel` out of the body of the request.
/// It uses the database that has been specified in the `DatabaseConfiguration`.
public struct Create<Model: DatabaseModel>: Handler {
    @Apodini.Environment(\.database)
    private var database: Fluent.Database
    
    @Parameter
    private var object: Model

    public func handle() -> Model? {
        // wait() will be removed once EventloopFuture is working again.
        // swiftlint:disable force_unwrap
        try! object.save(on: database).transform(to: object).wait()
    }
}
