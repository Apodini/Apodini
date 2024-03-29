//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// BP18
/// Checks whether a URL segment contains any CRUD verbs, which is discouraged.
/// Additional forbidden verbs can be passed in via the `CRUDVerbConfiguration`.
public class NoCRUDVerbsInURLPathSegments: URLSegmentBestPractice {
    public static var scope: BestPracticeScopes = .rest
    public static var category: BestPracticeCategories = .urlPath
    
    var checkedSegments = [String]()
    
    var configuration = CRUDVerbConfiguration()
    
    func checkSegment(segment: String, isParameter: Bool) -> Finding? {
        let containsCRUDVerb = configuration.forbiddenVerbs.contains { segment.lowercased().contains($0.lowercased()) }
        if containsCRUDVerb {
            return URLCRUDVerbsFinding.crudVerbFound(segment: segment)
        }
        return nil
    }
    
    public required init() { }
    
    init(configuration: CRUDVerbConfiguration) {
        self.configuration = configuration
    }
}

public struct CRUDVerbConfiguration: BestPracticeConfiguration {
    var forbiddenVerbs = ["get", "post", "remove", "delete", "put", "set", "create"]
    
    public func configure() -> BestPractice {
        NoCRUDVerbsInURLPathSegments(configuration: self)
    }
    
    public init(forbiddenVerbs: [String] = []) {
        self.forbiddenVerbs += forbiddenVerbs
    }
}

enum URLCRUDVerbsFinding: Finding, Equatable {
    case crudVerbFound(segment: String)
    
    var diagnosis: String {
        switch self {
        case .crudVerbFound(let segment):
            return "The path segment \(segment) contains one or more CRUD verbs"
        }
    }
}
