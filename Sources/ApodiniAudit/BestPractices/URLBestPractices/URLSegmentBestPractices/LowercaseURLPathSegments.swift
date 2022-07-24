//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

class LowercaseURLPathSegments: URLSegmentBestPractice {
    static var scope: BestPracticeScopes = .rest
    static var category: BestPracticeCategories = .urlPath
    var successMessage = "The path segments do not contain any uppercase letters"
    var checkedSegments = [String]()
    
    func checkSegment(segment: String, isParameter: Bool) -> Finding? {
        if segment.lowercased() != segment && !isParameter {
            return LowercasePathSegmentsFinding.uppercaseCharacterFound(segment: segment)
        }
        return nil
    }
    
    required init() { }
}

enum LowercasePathSegmentsFinding: Finding {
    case uppercaseCharacterFound(segment: String)
    
    var diagnosis: String {
        switch self {
        case .uppercaseCharacterFound(let segment):
            return "The path segment \(segment) contains one or more uppercase letters"
        }
    }
}
