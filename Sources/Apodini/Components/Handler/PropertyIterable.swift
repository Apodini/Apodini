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
/// `DynamicProperty`s or `Properties` as its children. The same restriction applies
/// to its recursive children nested inside `DynamicProperty`s or `Properties`.
public protocol PropertyIterable: Codable { }


public protocol PIHandler: Handler, PropertyIterable { }
