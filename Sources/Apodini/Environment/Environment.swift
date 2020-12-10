import Runtime

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
    
    private var content: Environment<Value>.Content
    private var values: EnvironmentValues
    
    public init(_ keyPath: KeyPath<EnvironmentValues, Value>) {
        content = .keyPath(keyPath)
        values = EnvironmentValues()
    }
    
    public var wrappedValue: Value {
        switch content {
        case let .value(value):
            return value
        case let .keyPath(keyPath):
            // not bound to a view, return the default value
            return values[keyPath: keyPath]
        }
    }

    /// Sets the value for the given KeyPath.
    mutating func setValue(_ value: Value, for keyPath: WritableKeyPath<EnvironmentValues, Value>) {
        self.values[keyPath: keyPath] = value
    }
}

extension Component {
    /// Sets the environment value for the given KeyPath on the component.
    /// - parameters:
    ///     - value: The value that should be set for the evironment.
    ///     - keyPath: The KeyPath that identifies the enviroment object to store  the given value in.
    public func withEnviromment<Value>(_ value: Value, for keyPath: WritableKeyPath<EnvironmentValues, Value>) -> Self {
        var selfRef = self
        do {
            let info = try typeInfo(of: type(of: self))

            for property in info.properties {
                if var child = (try property.get(from: selfRef)) as? Environment<Value> {
                    child.setValue(value, for: keyPath)
                    try property.set(value: child, on: &selfRef)
                }
            }
        } catch {
            print(error)
        }
        return selfRef
    }
}
