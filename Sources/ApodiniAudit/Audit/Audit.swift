//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

/// An `Audit` stores the report of an audit of a best practice for an endpoint.
struct Audit {
    var report: AuditReport
    var endpoint: AnyEndpoint
    var bestPracticeType: BestPractice.Type
}

/// A report for a single audit, including a message and a result.
public struct AuditReport {
    var message: String
    var auditResult: AuditResult
}

enum AuditResult {
    case success
    case fail
}

extension AuditReport: Hashable { }