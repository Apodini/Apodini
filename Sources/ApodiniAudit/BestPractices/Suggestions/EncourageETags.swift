//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

public class EncourageETags: BestPractice {
    public static var scope: BestPracticeScopes = .all
    public static var category: BestPracticeCategories = .caching
    
    public func check(into audit: Audit, _ app: Application) {
        /// Check whether the endpoint is a blob endpoint
        let typeString = String(describing: audit.endpoint[HandleReturnType.self].type)
        guard typeString.contains("Blob") else {
            return
        }
        
        audit.recordFinding(ETagsFinding.cacheableBlob)
    }
    
    required public init() { }
}

enum ETagsFinding: Finding {
    case cacheableBlob
    
    var diagnosis: String {
        switch self {
        case .cacheableBlob:
            return "This Endpoint returns blob data"
        }
    }
    
    var suggestion: String? {
        switch self {
        case .cacheableBlob:
            return "You can use ETags to enable caching for this endpoint"
        }
    }
}
