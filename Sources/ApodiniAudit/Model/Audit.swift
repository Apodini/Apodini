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
    var audits: [Audit]
}

/// An `Audit` stores the findings of a best practice for an endpoint.
/// There can be multiple findings, e.g. one for every URL segment of the endpoint.
public class Audit {
    var findings: [Finding] = []
    var endpoint: AnyEndpoint
    var bestPractice: BestPractice
    
    func recordFinding(_ message: String, _ assessment: Assessment) {
        findings.append(Finding(message: message, assessment: assessment))
    }
    
    init(_ endpoint: AnyEndpoint, _ bestPractice: BestPractice) {
        self.endpoint = endpoint
        self.bestPractice = bestPractice
    }
}

/// A finding for an audit, including a message and a result.
public struct Finding: Hashable {
    var message: String
    var assessment: Assessment
}

enum Assessment: Hashable {
    case pass
    case fail
}
