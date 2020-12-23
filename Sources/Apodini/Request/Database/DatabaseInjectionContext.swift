import Foundation
import Fluent

public protocol DatabaseInjectionContext {
    var key: FieldKey { get }
    var type: Any.Type { get }
}

public struct ModelInfo: DatabaseInjectionContext {
    public var key: FieldKey
    public var type: Any.Type
    
}

