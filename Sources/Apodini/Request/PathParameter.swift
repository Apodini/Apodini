import Foundation


/// A `@PathComponent` can be used in `Component`s to indicate that a part of a path is a parameter and can be read out in a `Handler`
@propertyWrapper
public struct PathParameter<Element> {
    var id = UUID()
    
    /// You can never access the wrapped value of a @PathParameter.
    /// Please use a `@Parameter` wrapped property within a `Handler` to access the path property.
    public var wrappedValue: Element {
        fatalError("""
            You can never access the wrapped value of a @PathParameter.
            Please use a `@Parameter` wrapped property within a `Handler` to access the path property.
        """)
    }
    
    /// Accessing the projected value allows you to pass the `@PathParameter` to a `Handler` or `Component`
    public var projectedValue: PathParameter {
        self
    }
    
    
    /// Creates a new `@PathParameter`
    public init() { }
    
    /// Creates a new `@PathParameter` based on a `@PathParameter` passed in from a different `Component`
    public init(_ pathParameter: PathParameter<Element>) {
        self.id = pathParameter.id
    }
}
