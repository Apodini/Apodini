//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

struct NoNumbersOrSymbolsInURLPathSegments: URLSegmentBestPractice {
    static var scope: BestPracticeScopes = .all
    static var category: BestPracticeCategories = .urlPath
    
    func checkSegment(segment: String, isParameter: Bool) -> Finding? {
        if segment.contains(where: { c in
            !c.isLetter
        }) {
            return NumberOrSymbolsInURLFinding.nonLetterCharacterFound(segment: segment)
        }
        return nil
    }
}

enum NumberOrSymbolsInURLFinding: Finding {
    case nonLetterCharacterFound(segment: String)
    
    var diagnosis: String {
        switch self {
        case .nonLetterCharacterFound(let segment):
            return "The segment \(segment) contains one or more non-letter characters."
        }
    }
}
