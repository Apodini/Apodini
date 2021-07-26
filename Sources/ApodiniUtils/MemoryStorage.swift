/// A local in-memory storage that can be used independently of the `Application.Storage`.
public protocol MemoryStorage {
    /// The type that should be saved in the storage
    associatedtype Object
    
    /// The singleton object. Initialize an instance of your class here.
    static var current: Self { get set }
    
    /// Stores the object.
    /// - Parameter object: The object that should be saved
    mutating func store(_ object: Object)
    /// Retrieves the stored object.
    /// - returns: `Object`
    func retrieve() -> Object?
}
