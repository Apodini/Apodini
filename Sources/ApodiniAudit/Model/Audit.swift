//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

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
    public var endpoint: AnyEndpoint
    var bestPractice: BestPractice
    
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
    var diagnosis: String { get }
    var suggestion: String? { get }
    var priority: Priority { get }
}

public extension Finding {
    var suggestion: String? {
        nil
    }
    
    var priority: Priority {
        .normal
    }
}
