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
    /// - Note: This intentionally is a static function rather than an initializer, the reason being that,
    ///         due to the fact that this function takes `Any`, it would cause the typechecker to, in some cases,  prefer this `init` overload
    ///         over other better-matching overloads when initialising a string from some (generic) value.
    ///         Note that this even applies if the initializer has a named argument: if its called `init?(int8Tuple:)` and you write code like
    ///         `[Substring]().first.flatMap(String.init)`, the typechecker will resolve the `String.init` to the tuple-taking overload,
    ///         rather than the probably intended `String.init(Substring)` overload.
    public static func createFromInt8Tuple(_ int8Tuple: Any) -> String? {
        let mirror = Mirror(reflecting: int8Tuple)
        guard mirror.displayStyle == .tuple else {
            return nil
        }
        var str = ""
        str.reserveCapacity(mirror.children.count)
        for (_, value) in mirror.children {
            guard let value = value as? Int8 else {
                return nil
            }
            str.append(String(UnicodeScalar(UInt8(value))))
        }
        return str
    }
    
    
    /// Returns a copy of the string, with all quotation marks (both single `'` and double `"`) escaped.
    /// This function is intended for strings which are used as parameters to shell commands.
    public func shellEscaped() -> String {
        return self
            .replacingOccurrences(of: "'", with: #"\'"#)
            .replacingOccurrences(of: "\"", with: #"\""#)
    }
}
