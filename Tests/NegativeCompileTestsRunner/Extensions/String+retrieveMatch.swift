//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Foundation

extension String {
    /// Retrieves the substring of a matched group of a `NSTextCheckingResult`.
    /// - Parameters:
    ///   - match: The match (corresponding to the self String)
    ///   - at: The group number to retrieve
    /// - Returns: The matched substring for the given group
    func retrieveMatch(match: NSTextCheckingResult, at: Int) -> String {
        let rangeBounds = match.range(at: at)
        guard let range = Range(rangeBounds, in: self) else {
            return ""
        }

        return String(self[range])
    }
}
