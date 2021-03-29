//
//  File.swift
//  
//
//  Created by Eldi Cano on 29.03.21.
//

import Foundation

/// A helper protocol that all primitive types (as considered in Apodini) conform to
protocol Primitive: Value {}

extension Int: Primitive {}
extension Int32: Primitive {}
extension Int64: Primitive {}
extension UInt: Primitive {}
extension UInt32: Primitive {}
extension UInt64: Primitive {}
extension Bool: Primitive {}
extension String: Primitive {}
extension Double: Primitive {}
extension Float: Primitive {}
