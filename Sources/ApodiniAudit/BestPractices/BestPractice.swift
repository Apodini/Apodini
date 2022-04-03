//
//  File.swift
//  
//
//  Created by Simon Bohnen on 3/21/22.
//

import Foundation
import Apodini

protocol BestPractice {
    static var category: BestPracticeCategory { get }
    
    static func check(_ app: Application, _ endpoint: AnyEndpoint) -> AuditReport
}

extension BestPractice {
    static func audit(_ app: Application, _ endpoint: AnyEndpoint) -> Audit {
        let auditReport = check(app, endpoint)
        return Audit(report: auditReport, endpoint: endpoint, bestPracticeType: Self.self)
    }
}

enum BestPracticeCategory {
    // TODO complete list from Masse
    case urlPath, statusCode
}
