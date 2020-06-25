import NIO

protocol Model {
    static var tableName: String { get }
}

protocol Database {
    func fetch<M: Model>(on eventLoop: EventLoop) -> EventLoopFuture<[M]>
}

@propertyWrapper
struct CurrentDatabase<D: Database> {
    var wrappedValue: D
    
    init() {
        fatalError("Not implemented")
    }
}
