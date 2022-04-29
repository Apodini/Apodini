//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

/// An `Audit` stores the reports of an audit of a best practice for an endpoint.
/// There can be multiple reports, e.g. one for every URL segment of the endpoint.
class Audit {
    var reports: [AuditReport] = []
    var endpoint: AnyEndpoint
    var bestPracticeType: BestPractice.Type
    
    func report(_ message: String, _ result: AuditResult) {
        reports.append(AuditReport(message: message, auditResult: result))
    }
    
    init(_ endpoint: AnyEndpoint, _ bestPracticeType: BestPractice.Type) {
        self.endpoint = endpoint
        self.bestPracticeType = bestPracticeType
    }
}

/// A report for an audit, including a message and a result.
public struct AuditReport {
    var message: String
    var auditResult: AuditResult
}

enum AuditResult {
    case success
    case fail
}

extension AuditReport: Hashable { }
