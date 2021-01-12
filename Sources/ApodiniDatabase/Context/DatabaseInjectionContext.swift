import Foundation
import Fluent

///A Protocol which provides info about the expected the type of a `FieldKey`.
public protocol DatabaseInjectionContext {
    ///A `Fluent.FieldKey`
    var key: FieldKey { get }
    ///The expected type for the fieldkey
    var value: AnyConcreteCodable { get }
}

///A struct implementing `DatabaseInjectionContext` and containing a fieldkey and the expected type for that key.
public struct ModelInfo: DatabaseInjectionContext, Equatable {
    ///A concrete `Fluent.FieldKey`
    public var key: FieldKey
    ///A concrete type for that fieldkey
    public var value: AnyConcreteCodable
    
    public static func == (lhs: ModelInfo, rhs: ModelInfo) -> Bool {
        lhs.key == rhs.key
    }
}
