public protocol EnvironmentKey {
    associatedtype Value
    
    static var defaultValue: Self.Value { get }
}

public struct EnvironmentValues: CustomStringConvertible {
    var values: [ObjectIdentifier: Any] = [:]
    
    public init() { }
    
    public subscript<K>(key: K.Type) -> K.Value where K: EnvironmentKey {
        get {
            if let value = values[ObjectIdentifier(key)] as? K.Value {
                return value
            }
            return K.defaultValue
        }
        set {
            values[ObjectIdentifier(key)] = newValue
        }
    }
    
    public var description: String {
        ""
    }
}

protocol DynamicProperty { }

@propertyWrapper
public struct Environment<Value>: DynamicProperty {
    internal enum Content {
        case keyPath(KeyPath<EnvironmentValues, Value>)
        case value(Value)
    }
    
    internal var content: Environment<Value>.Content
    
    public init(_ keyPath: KeyPath<EnvironmentValues, Value>) {
        content = .keyPath(keyPath)
    }
    
    public var wrappedValue: Value {
        switch content {
        case let .value(value):
            return value
        case let .keyPath(keyPath):
            // not bound to a view, return the default value
            return EnvironmentValues()[keyPath: keyPath]
        }
    }
}
