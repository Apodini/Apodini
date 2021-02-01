import Fluent
import Apodini

/// Creates, if possible, an array of object in the database that conform to `DatabaseModel`
/// See also `Create`.
public struct CreateAll<Model: DatabaseModel>: Handler {
    @Apodini.Environment(\.database)
    private var database: Fluent.Database
    
    @Environment(\.eventLoopGroup)
    private var eventLoopGroup: EventLoopGroup
    
    @Parameter
    private var objects: [Model]

    public func handle() -> EventLoopFuture<[Model]> {
        eventLoopGroup.next().flatten(
            objects.map { object in
                object.save(on: database).transform(to: object)
            }
        )
    }
    
    public init() {}
}
