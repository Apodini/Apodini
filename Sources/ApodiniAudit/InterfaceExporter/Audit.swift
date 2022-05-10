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
public class AuditReport {
    var findings: [AuditFinding] = []
    var endpoint: AnyEndpoint
    var bestPractice: BestPractice
    
    func recordFinding(_ message: String, _ result: AuditResult) {
        findings.append(AuditFinding(message: message, result: result))
    }
    
    init(_ endpoint: AnyEndpoint, _ bestPractice: BestPractice) {
        self.endpoint = endpoint
        self.bestPractice = bestPractice
    }
}

/// A report for an audit, including a message and a result.
public struct AuditFinding {
    var message: String
    var result: AuditResult
}

enum AuditResult: Hashable {
    case success
    case fail
}

extension AuditFinding: Hashable { }
