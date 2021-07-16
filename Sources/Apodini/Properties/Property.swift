//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation


/// This protocol is implemented by all of Apodini's property wrappers that are used access functionality or information on a handling `Component`.
/// - Warning: Only structs can be a `Property`
public protocol Property { }

/// `DynamicProperty` allows for wrapping `Property`s while maintaining their functionality. By conforming a `struct` to `DynamicProperty`
/// you make this `struct`'s properties discoverable to the Apodini runtime framework. This can be used to e.g. combine
/// two property wrappers provided by the Apodini framework into one that merges their functionality
/// - Warning: Only structs can be a `DynamicProperty`
public protocol DynamicProperty: Property {
    /// The `namingStrategy` is called when the framework decides to interact with one of
    /// the `DynamicProperty`'s properties. By default it assumes the label of this property to be the
    /// desired name of the property.
    /// This behavior can be changed by overriding the `namingStrategy`. E.g. to expose an internal
    /// `@Parameter` using the name that was given to the wrapping `DynamicProperty` the
    /// `namingStrategy` would be to return `names[names.count-2]`.
    func namingStrategy(_ names: [String]) -> String?
}

public extension DynamicProperty {
    /// The default `namingStrategy` is to use the target element's label.
    func namingStrategy(_ names: [String]) -> String? {
        names.last
    }
}
