//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

public protocol BestPractice {
    static var scope: BestPracticeScope { get }
    static var category: BestPracticeCategory { get }
    
    static func check(_ app: Application, _ endpoint: AnyEndpoint) -> AuditReport
}

extension BestPractice {
    static func audit(_ app: Application, _ endpoint: AnyEndpoint) -> Audit {
        let auditReport = check(app, endpoint)
        return Audit(report: auditReport, endpoint: endpoint, bestPracticeType: Self.self)
    }
}

public enum BestPracticeCategory {
    // TODO complete list from Masse
    case urlPath, statusCode
}

public enum BestPracticeScope {
    case all, restOnly
}
