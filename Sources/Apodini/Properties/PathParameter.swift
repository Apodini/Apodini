import Foundation
import ApodiniUtils

// Be aware that "toplevel" `PathParameter`s can also be defined by just
// defining a `@Parameter(.http(.path))` in the `Handler`.

/// A `@PathComponent` can be used in `Component`s to indicate that a part of a path is a parameter and can be read out in a `Handler`
@propertyWrapper
public struct PathParameter<Element: Codable & LosslessStringConvertible>: Decodable {
    var id = UUID()
    var identifyingType: IdentifyingType?
    
    /// You can never access the wrapped value of a @PathParameter.
    /// Please use a `@Parameter` wrapped property within a `Handler` to access the path property.
    public var wrappedValue: Element {
        fatalError(
            """
            You can never access the wrapped value of a @PathParameter.
            Please use a `@Parameter` wrapped property within a `Handler` to access the path property.
            """
        )
    }
    
    /// Accessing the projected value allows you to pass the `@PathParameter` to a `Handler` or `Component`
    public var projectedValue: Binding<Element> {
        parameter.projectedValue
    }
    
    
    /// Creates a new `@PathParameter`
    public init() {
        precondition(!isOptional(Element.self), "A `PathParameter` cannot annotate a property with Optional type!")
    }

    /// Creates a new `@PathParameter` specifically stating the type it identifies.
    /// The identified type must conform to `Identifiable` and the property type of the `PathParameter`
    /// must match the type of the `id` property of the  identified type.
    ///
    /// - Parameter type: The type the PathParameter value identifies.
    public init<Type: Encodable & Identifiable>(identifying type: Type.Type = Type.self) where Element == Type.ID {
        self.init()
        self.identifyingType = IdentifyingType(identifying: type)
    }
    
    /// Required because `WebService` conform to `ParsableCommand` which conforms to `Decodable`
    /// Can't be automatically synthesized by Swift
    public init(from decoder: Decoder) throws {}
}

extension PathParameter {
    /// A `Parameter` that can be used to pass the `PathParameter` to a `Handler` that contains a `@Parameter` and not a `@Binding`.
    public var parameter: Parameter<Element> {
        Parameter(from: id, identifying: identifyingType)
    }
}
