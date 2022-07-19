//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

public struct NoCRUDVerbsInURLPathSegments: URLSegmentBestPractice {
    public static var scope: BestPracticeScopes = .rest
    public static var category: BestPracticeCategories = .urlPath
    var successMessage = "The path segments do not contain any CRUD verbs"
    private var crudVerbs = ["get", "post", "remove", "delete", "put"]
    
    func checkSegment(segment: String, isParameter: Bool) -> FindingBase? {
        let containsCRUDVerb = crudVerbs.contains { segment.lowercased().contains($0) }
        if containsCRUDVerb {
            return Finding.crudVerbFound(segment: segment)
        }
        return nil
    }
    
    public init() { }
    
    enum Finding: FindingProtocol {
        case crudVerbFound(segment: String)
        
        var diagnosis: String {
            switch self {
            case .crudVerbFound(let segment):
                return "The path segment \(segment) contains one or more CRUD verbs!"
            }
        }
    }
}
