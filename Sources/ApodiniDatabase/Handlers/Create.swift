import Fluent
import Apodini

public struct Create<T: DatabaseModel>: Handler {
    
    @Apodini.Environment(\.database)
    var database: Fluent.Database
    
    @Parameter
    var object: T

    public func handle() -> String {
        object.save(on: database).map({ _ in
            self.object
        })
        return "Created"
    }
}
