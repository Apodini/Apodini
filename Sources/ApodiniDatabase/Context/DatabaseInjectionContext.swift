import Foundation
import Fluent

///A Protocol which provides info about the expected the type of a `FieldKey`.
public protocol DatabaseInjectionContext {
    var key: FieldKey { get }
    var type: Any.Type { get }
}

internal struct ModelInfo: DatabaseInjectionContext {
    public var key: FieldKey
    public var type: Any.Type
    
}

