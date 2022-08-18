//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

/// A report contains the ``Audit``s resulting from running a best practice audit on a ``WebService``.
public struct Report {
    var audits = [Audit]()
    
    mutating func addAudit(_ audit: Audit) {
        audits.append(audit)
    }
}

/// An `Audit` stores the findings of a best practice for an endpoint.
/// There can be multiple findings, e.g. one for every URL segment of the endpoint.
public class Audit {
    var findings: [Finding] = []
    /// The ``Endpoint`` this audit lists ``Finding``s for.
    public var endpoint: AnyEndpoint
    var bestPractice: BestPractice
    
    /// Record a finding into this audit.
    public func recordFinding(_ finding: Finding) {
        findings.append(finding)
    }
    
    init(_ endpoint: AnyEndpoint, _ bestPractice: BestPractice) {
        self.endpoint = endpoint
        self.bestPractice = bestPractice
    }
}

/// A finding for an audit, including a diagnosis and possibly a suggestion.
public protocol Finding {
    /// The diagnosis of this finding.
    var diagnosis: String { get }
    /// An improvement suggestion to resolve this best practice violation.
    var suggestion: String? { get }
    /// The priority assigned to this Finding. Overrides the priority of the `BestPractice` which the ``Audit`` that contains this finding is associated with.
    var priority: Priority { get }
}

/// Default values for optional attributes.
public extension Finding {
    /// By default, there is no improvement suggestion
    var suggestion: String? {
        nil
    }
    
    /// The default priority is .normal.
    var priority: Priority {
        .normal
    }
}
