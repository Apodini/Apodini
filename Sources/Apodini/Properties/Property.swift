//
//  Property.swift
//  
//
//  Created by Max Obermeier on 09.12.20.
//

import Foundation

/// This protocol is implemented by all of Apodini's property wrappers that are used access functionality or information
/// on a handling `Component`.
/// - Precondition: Only structs can be a `Property`
public protocol Property { }

/// `DynamicProperty` allows for wrapping `Property`s while maintianing their functionality. By conforming
/// a `struct` to `DynamicProperty` you make this `struct`'s properties discoverable to the Apodini
/// runtime framework. This can be used to e.g. combine two property wrappers provided by the Apodini framework
/// into one that merges their functionality
/// - Precondition: Only structs can be a `DynamicProperty`
public protocol DynamicProperty: Property { }
