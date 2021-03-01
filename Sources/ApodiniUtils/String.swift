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
}
