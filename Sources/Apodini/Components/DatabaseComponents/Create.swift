import Foundation
import Fluent

public struct Create<T: DatabaseModel>: Component {
    
    @_Database
    var database: Fluent.Database
    
    @Parameter
    var object: T

    public func handle() -> EventLoopFuture<T> {
        return object.save(on: database).map({ _ in
            self.object
        })
    }
}
