//
//  File.swift
//  
//
//  Created by Simon Bohnen on 4/3/22.
//

import Foundation
import Apodini

/// An `Audit` stores the report of an audit of a best practice for an endpoint.
struct Audit {
    var report: AuditReport
    var endpoint: AnyEndpoint
    var bestPracticeType: BestPractice.Type
}

struct AuditReport {
    var message: String
    var auditResult: AuditResult
}

enum AuditResult {
    case success
    case fail
}
