//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
// 

/// Protocol to store and restore the values of property wrappers like `@Environment` or `@PathParameter` in the `WebService`
public protocol ArgumentParserStoreable {
    /// Stores the values of the property wrappers in a passed dictionary keyed by the name of the wrapped value
    /// - Parameters:
    ///    - store: Used to store the values of the wrapped values of the property wrappers
    ///    - key: The name of the wrapped value of the property wrapper, used as a key to store the values in a dictionary
    func store(in store: inout [String: any ArgumentParserStoreable], keyedBy key: String)
    
    /// Restores the values of the property wrappers from a passed dictionary keyed by the name of the wrapped value
    /// - Parameters:
    ///    - store: Used to restore the values of the wrapped values of the property wrappers
    ///    - key: The name of the wrapped value of the property wrapper, used as a key to store the values in a dictionary
    func restore(from store: [String: any ArgumentParserStoreable], keyedBy key: String)
}
