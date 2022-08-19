//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

/// Encourages the use of ETags when the return type of an endpoint is ``Blob``.
/// BP55
public class EncourageETags: BestPractice {
    public static var scope: BestPracticeScopes = .all
    public static var category: BestPracticeCategories = .caching
    
    private var checkedHandlerNames = [String]()
    
    public func check(into audit: Audit, _ app: Application) {
        let handlerName = audit.endpoint[HandlerReflectiveName.self].rawValue
        guard !checkedHandlerNames.contains(handlerName) else {
            return
        }
        
        checkedHandlerNames.append(handlerName)
        
        /// Check whether the endpoint is a blob endpoint
        let typeString = String(describing: audit.endpoint[HandleReturnType.self].type)
        guard typeString.contains("Blob") else {
            return
        }
        
        audit.recordFinding(ETagsFinding.cacheableBlob)
    }
    
    public required init() { }
}

enum ETagsFinding: Finding {
    case cacheableBlob
    
    var diagnosis: String {
        switch self {
        case .cacheableBlob:
            return "This handler returns blob data"
        }
    }
    
    var suggestion: String? {
        switch self {
        case .cacheableBlob:
            return "You can use ETags to enable caching for this endpoint!"
        }
    }
}
