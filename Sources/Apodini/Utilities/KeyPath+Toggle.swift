//
//  Created by Nityananda on 25.01.21.
//

extension KeyPath where Value == Bool {
    /// Performs a logical NOT operation on a KeyPath.
    ///
    /// Compare
    /// ```
    /// subviews.filter { !$0.isHidden }
    /// ```
    /// to
    /// ```
    /// subviews.filter(!\.isHidden)
    /// ```
    ///
    /// [Source](https://www.swiftbysundell.com/articles/custom-query-functions-using-key-paths/)
    ///
    /// - Parameter keyPath: The KeyPath to negate.
    /// - Returns: A closure that can be passed to higher-order functions.
    static prefix func ! (keyPath: KeyPath<Root, Value>) -> (Root) -> Bool {
        { !$0[keyPath: keyPath] }
    }
}
