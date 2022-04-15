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
    static var scope: BestPracticeScopes { get }
    static var category: BestPracticeCategories { get }
    
    static func check(_ app: Application, _ endpoint: AnyEndpoint) -> AuditReport
}

extension BestPractice {
    static func audit(_ app: Application, _ endpoint: AnyEndpoint) -> Audit {
        let auditReport = check(app, endpoint)
        return Audit(report: auditReport, endpoint: endpoint, bestPracticeType: Self.self)
    }
}

public struct BestPracticeCategories: OptionSet {
    // TODO complete list from Masse
    public let rawValue: Int
    
    static let urlPath      = BestPracticeCategories(rawValue: 1 << 0)
    static let statusCode   = BestPracticeCategories(rawValue: 1 << 1)
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public struct BestPracticeScopes: OptionSet {
    public let rawValue: Int
    
    static let http = BestPracticeScopes(rawValue: 1 << 0)
    static let rest = BestPracticeScopes(rawValue: 1 << 1)
    
    static let all: BestPracticeScopes = [.http, .rest]
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
