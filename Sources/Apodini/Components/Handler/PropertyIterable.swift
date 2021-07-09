//
//  PropertyIterable.swift
//  
//
//  Created by Max Obermeier on 09.07.21.
//

import Foundation

/// The children and recursive children of an `PropertyIterable` element can be
/// accessed by Apodini in a performant manner without usage of runtime reflection.
///
/// A `PropertyIterable` object may only have Apodini-defined `Property`s,
/// as its children. The same restriction applies to any recursive children nested inside
/// a `DynamicProperty` or `Properties` element.
public protocol PropertyIterable: Codable { }
