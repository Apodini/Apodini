import Fluent
import Foundation
import Apodini

///A protocol all Models that are used with `ApodiniDatabase` need conform to
public protocol DatabaseModel: Model, Apodini.Content {
    ///Has to be overwritten to use `Update` handler.
    func update(_ object: Self)
}

internal extension DatabaseModel {
    static func fieldKey(for string: String) -> FieldKey {
        if let key = Self.keys.first(where: { $0.description == string }) {
            return key
        } else {
            fatalError("Unexpectedly found nil. Failed to find a Fieldkey under the given string \(string)")
        }
    }
}
