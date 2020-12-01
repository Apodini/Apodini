import Foundation

public protocol PropertyOption {
    /**
        Combines two instances of the same type of option into a single one.
        This can include any logic on how to combine these options.

        Defaults to returning the left hand side
     */
    static func & (lhs: Self, rhs: Self) -> Self
}

extension PropertyOption where Self: OptionSet {

    public static func & (lhs: Self, rhs: Self) -> Self {
        return lhs.union(rhs)
    }

}

extension PropertyOption {

    public static func & (lhs: Self, rhs: Self) -> Self {
        return lhs
    }

}
