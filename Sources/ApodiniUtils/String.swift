//
//  String.swift
//  
//
//  Created by Lukas Kollmer on 2021-02-18.
//

import Foundation

extension String {
    /// Returns the string, with the specified suffix appended if necessary
    public func withSuffix(_ suffix: String) -> String {
        guard !hasSuffix(suffix) else {
            return self
        }
        return self + suffix
    }
    
    /// Creates a string by interpreting a tuple of `UInt8` values as a C string.
    /// This is useful when working with C libraries, where the swift importer sometimes represents C-style arrays as tuples.
    public init?(int8Tuple: Any) {
        let mirror = Mirror(reflecting: int8Tuple)
        guard mirror.displayStyle == .tuple else {
            return nil
        }
        self.init()
        for (_, value) in mirror.children {
            guard let value = value as? Int8 else {
                return
            }
            append(String(UnicodeScalar(UInt8(value))))
        }
    }
}
