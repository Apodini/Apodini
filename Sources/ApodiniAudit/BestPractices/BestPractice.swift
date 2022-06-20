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
    /// The scope of this best practice (http or rest)
    static var scope: BestPracticeScopes { get }
    /// The category this best practice fits into
    static var category: BestPracticeCategories { get }
    
    /// Check this best practice into the given AuditReport.
    func check(into report: AuditReport, _ app: Application)
    
    init()
}

extension BestPractice {
    func check(for endpoint: AnyEndpoint, _ app: Application) -> AuditReport {
        let report = AuditReport(endpoint, self)
        check(into: report, app)
        if report.findings.isEmpty {
            // TODO generate success message
        }
        return report
    }
}

public struct BestPracticeCategories: OptionSet {
    // FUTURE complete list from Masse
    public let rawValue: Int
    
    static let urlPath      = BestPracticeCategories(rawValue: 1 << 0)
    static let statusCode   = BestPracticeCategories(rawValue: 1 << 1)
    static let method       = BestPracticeCategories(rawValue: 1 << 2)
    
    static let linguistic   = BestPracticeCategories(rawValue: 1 << 31)
    
    static let linguisticURL: BestPracticeCategories = [.linguistic, .urlPath]
    
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
