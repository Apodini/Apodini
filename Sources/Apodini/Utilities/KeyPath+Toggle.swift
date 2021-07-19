//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

extension KeyPath where Value == Bool {
    /// Performs a logical NOT operation on a KeyPath.
    ///
    /// Compare
    /// ```
    /// subviews.filter { !$0.isHidden }
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
    public static prefix func ! (keyPath: KeyPath<Root, Value>) -> (Root) -> Value {
        { !$0[keyPath: keyPath] }
    }
}
