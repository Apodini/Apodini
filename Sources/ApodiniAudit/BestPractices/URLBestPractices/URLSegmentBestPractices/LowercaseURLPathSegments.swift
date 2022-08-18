//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// BP9
/// Checks whether URL path segments contain only lowercase letters.
public class LowercaseURLPathSegments: URLSegmentBestPractice {
    public static var scope: BestPracticeScopes = .rest
    public static var category: BestPracticeCategories = .urlPath
    var successMessage = "The path segments do not contain any uppercase letters"
    var checkedSegments = [String]()
    
    func checkSegment(segment: String, isParameter: Bool) -> Finding? {
        if segment.lowercased() != segment && !isParameter {
            return LowercasePathSegmentsFinding.uppercaseCharacterFound(segment: segment)
        }
        return nil
    }
    
    public required init() { }
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
