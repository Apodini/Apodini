//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

extension String {
    func getLastSegment() -> String {
        // Split segment into words
        let segmentParts = self.splitIntoWords(delimiters: [
            .uppercase,
            .notAlphaNumerical
        ])
        
        guard let lastPart = segmentParts.last else {
            return ""
        }
        
        // Build cleanup regex
        guard let cleanUpRegex = try? NSRegularExpression(pattern: "[^a-zA-Z0-9]") else {
            fatalError("Could not build regexes")
        }
        
        let cleanedLastPart = cleanUpRegex.stringByReplacingMatches(
            in: lastPart,
            options: [],
            range: NSRange(location: 0, length: lastPart.count),
            withTemplate: ""
        )
        return cleanedLastPart
    }
}
