import Foundation
import FluentKit

///A Protocol which provides info about the expected the type of a `FieldKey`.
protocol DatabaseInjectionContext {
    ///A `FluentKitFieldKey`
    var key: FieldKey { get }
    ///The expected type for the fieldkey
    var value: TypeContainer { get }
}

///A struct implementing `DatabaseInjectionContext` and containing a fieldkey and the expected type for that key.
struct ModelInfo: DatabaseInjectionContext {
    ///A concrete `FluentKitFieldKey`
    var key: FieldKey
    ///A concrete type for that fieldkey
    var value: TypeContainer
}
