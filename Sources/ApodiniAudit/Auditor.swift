//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

public class Auditor {
    static var audits: [Audit] = []
    
    public static func audit<H: Handler>(_ app: Application, _ endpoint: Endpoint<H>) {
        // Audit the given endpoint.
        // Iterate over all best practices. Using reflection?
        // figure out which ones are silenced for the current endpoint
        for bestPracticeType in bestPractices {
            audits.append(bestPracticeType.audit(app, endpoint))
        }
    }
}

extension Auditor {
    static let bestPractices: [BestPractice.Type] = [
        AppropriateLengthForURLPathSegments.self
    ]
}
