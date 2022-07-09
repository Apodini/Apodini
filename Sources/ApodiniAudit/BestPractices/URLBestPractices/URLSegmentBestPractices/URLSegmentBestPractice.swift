//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

protocol URLSegmentBestPractice: BestPractice {
    var successMessage: String { get }
    
    func checkSegment(segment: String) -> String?
}

extension URLSegmentBestPractice {
    public func check(into audit: Audit, _ app: Application) {
        for segment in audit.endpoint.absolutePath {
            if case .string(let identifier) = segment,
                let failMessage = checkSegment(segment: identifier) {
                audit.recordFinding(failMessage, .fail)
            }
        }
    }
}
