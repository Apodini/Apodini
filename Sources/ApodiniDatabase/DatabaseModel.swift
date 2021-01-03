import Fluent
import Vapor

///A protocol all Models that are used with `ApodiniDatabase` need conform to
public protocol DatabaseModel: Content, Model {
    ///Has to be overwritten to use `Update` handler.
    func update(_ object: Self)
}

internal extension DatabaseModel {
    
    static func fieldKey(for string: String) -> FieldKey {
        return Self.keys.first(where: { $0.description == string })!
    }
}
