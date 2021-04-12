//
//  File.swift
//  
//
//  Created by Eldi Cano on 12.04.21.
//

import Foundation

/**
 If no `encode(to:)` method is implemented, by default `encodeIfPresent(:forKey:)`
 is called on optionals. Default implementations of
 `encodeIfPresent` first unwrapp the optional value and only encode if the value is
 non-nil. By overriding these methods we can still find out if the type of an encodable
 value is optional
 */

extension KeyedEncodingContainerProtocol {
    public mutating func encodeIfPresent(
        _ value: Bool?,
        forKey key: Key
    ) throws {
        try encode(value, forKey: key)
    }
    
    public mutating func encodeIfPresent(
        _ value: String?,
        forKey key: Key
    ) throws {
        try encode(value, forKey: key)
    }
    
    public mutating func encodeIfPresent(
        _ value: Double?,
        forKey key: Key
    ) throws {
        try encode(value, forKey: key)
    }
    
    public mutating func encodeIfPresent(
        _ value: Float?,
        forKey key: Key
    ) throws {
        try encode(value, forKey: key)
    }
    
    public mutating func encodeIfPresent(
        _ value: Int?,
        forKey key: Key
    ) throws {
        try encode(value, forKey: key)
    }
    
    public mutating func encodeIfPresent(
        _ value: Int8?,
        forKey key: Key
    ) throws {
        try encode(value, forKey: key)
    }
    
    public mutating func encodeIfPresent(
        _ value: Int16?,
        forKey key: Key
    ) throws {
        try encode(value, forKey: key)
    }
    
    public mutating func encodeIfPresent(
        _ value: Int32?,
        forKey key: Key
    ) throws {
        try encode(value, forKey: key)
    }
    
    public mutating func encodeIfPresent(
        _ value: Int64?,
        forKey key: Key
    ) throws {
        try encode(value, forKey: key)
    }
    
    public mutating func encodeIfPresent(
        _ value: UInt?,
        forKey key: Key
    ) throws {
        try encode(value, forKey: key)
    }
    
    public mutating func encodeIfPresent(
        _ value: UInt8?,
        forKey key: Key
    ) throws {
        try encode(value, forKey: key)
    }
    
    public mutating func encodeIfPresent(
        _ value: UInt16?,
        forKey key: Key
    ) throws {
        try encode(value, forKey: key)
    }
    
    public mutating func encodeIfPresent(
        _ value: UInt32?,
        forKey key: Key
    ) throws {
        try encode(value, forKey: key)
    }
    
    public mutating func encodeIfPresent(
        _ value: UInt64?,
        forKey key: Key
    ) throws {
        try encode(value, forKey: key)
    }
    
    public mutating func encodeIfPresent<T: Encodable>(
        _ value: T?,
        forKey key: Key
    ) throws {
        try encode(value, forKey: key)
    }
}
