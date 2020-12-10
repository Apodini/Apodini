import Foundation


/// A `@PathComponent` can be used in `Component`s to indicate that a part of a path is a parameter and can be read out in a `Handler`
@propertyWrapper
public struct PathParameter<Element: Codable & LosslessStringConvertible> {
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
    public var projectedValue: Parameter<Element> {
        Parameter(from: id)
    }
    
    
    /// Creates a new `@PathParameter`
    public init() { }
    
    /// Creates a new `@PathParameter` based on a `@PathParameter` passed in from a different `Component`
    public init(_ parameter: Parameter<Element>) {
        guard let httpOptions = parameter.option(for: .http), case httpOptions = HTTPParameterMode.path else {
            fatalError("Only @Parameters with the `.http(.path)` option should be passed down the `Component` tree.")
        }
        
        self.id = parameter.pathId
    }
}
