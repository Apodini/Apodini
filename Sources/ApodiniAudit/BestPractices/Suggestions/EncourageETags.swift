//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

struct EncourageETags: BestPractice {
    static var scope: BestPracticeScopes = .http
    static var category: BestPracticeCategories = .caching
    
    func check(into audit: Audit, _ app: Application) {
        /// Check whether the endpoint is a blob endpoint
        guard audit.endpoint[HandleReturnType.self].type == Blob.self else {
            return
        }
        
        audit.recordFinding(Finding.cacheableBlob)
    }
    
    enum Finding: FindingProtocol {
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
}
