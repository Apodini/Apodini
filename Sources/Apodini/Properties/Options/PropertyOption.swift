import Foundation


/// A type erasure of a `PropertyOption`
public struct AnyPropertyOption<PropertyNameSpace> {
    /// A type erased `PropertyOptionKey` identifying the `AnyPropertyOption`
    let key: AnyPropertyOptionKey
    /// The value associated with the `key`
    let value: Any
    
    
    /// Creates a new type erased `PropertyOption`
    /// - Parameters:
    ///   - key: A type erased `PropertyOptionKey` identifying the `AnyPropertyOption`
    ///   - value: The value associated with the `key`
    public init<Option>(key: PropertyOptionKey<PropertyNameSpace, Option>, value: Option) {
        self.key = key
        self.value = value
    }
}


/// A value that can be associated with a `PropertyOptionKey` that can be collected in an `PropertyOptionSet`
public protocol PropertyOption {
    /// Combines two instances of the same type of `PropertyOption` into a single one.
    /// This can include any logic on how to combine `PropertyOption`s.
    ///
    /// Defaults to returning the left hand side
    /// - Parameters:
    ///   - lhs: The left hand side `PropertyOption` that should be combined
    ///   - rhs: The right hand side `PropertyOption` that should be combined
    /// - Returns: The combined `PropertyOption`
    static func & (lhs: Self, rhs: Self) -> Self
}


extension PropertyOption where Self: OptionSet {
    /// Combines two `PropertyOption`s if they `OptionSet` using a union on `OptionSet`s
    /// - Parameters:
    ///   - lhs: The left hand side `PropertyOption` conforming to `OptionSet` that should be combined
    ///   - rhs: The right hand side `PropertyOption` conforming to `OptionSet` that should be combined
    /// - Returns: The combined `PropertyOption`
    public static func & (lhs: Self, rhs: Self) -> Self {
        lhs.union(rhs)
    }
}


extension PropertyOption {
    /// Combines two instances of the same type of option into a single one.
    /// This can include any logic on how to combine these options.
    ///
    /// Defaults to returning the left hand side
    /// - Parameters:
    ///   - lhs: The left hand side `PropertyOption` that should be combined
    ///   - rhs: The right hand side `PropertyOption` that should be combined
    /// - Returns: The combined `PropertyOption`
    public static func & (lhs: Self, rhs: Self) -> Self {
        lhs
    }
}
