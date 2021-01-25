//
//  Created by Nityananda on 25.01.21.
//

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
/// Source: https://www.swiftbysundell.com/articles/custom-query-functions-using-key-paths/
///
/// - Parameter keyPath: The KeyPath to negate.
/// - Returns: A closure that can be passed to higher-order functions.
prefix func !<T>(keyPath: KeyPath<T, Bool>) -> (T) -> Bool {
    
    let x = !true
    return { !$0[keyPath: keyPath] }
}
