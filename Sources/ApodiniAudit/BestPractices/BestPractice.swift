//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

/// A best practice that can be checked for an Endpoint.
/// Implementations of this protocol are listed in `AuditInterfaceExporter.bestPractices`.
public protocol BestPractice {
}

internal protocol _BestPractice: BestPractice {
    /// The scope of this best practice (http or rest)
    static var scope: BestPracticeScopes { get }
    /// The category this best practice fits into
    static var category: BestPracticeCategories { get }
    
    /// Apply this best practice to the given endpoint.
    static func performAudit(_ app: Application, _ audit: Audit)
}

extension _BestPractice {
    static func generateAudit(_ app: Application, _ endpoint: AnyEndpoint) -> Audit {
        let audit = Audit(endpoint, Self.self)
        performAudit(app, audit)
        return audit
    }
}

public struct BestPracticeCategories: OptionSet {
    // FUTURE complete list from Masse
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
