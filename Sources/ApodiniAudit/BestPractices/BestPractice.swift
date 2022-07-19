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
    /// This best practice's priority. Can be overwritten by a higher priority of an individual finding.
    static var priority: Priority { get }
    
    /// Check this `BestPractice` into the given `Audit`.
    /// The `Audit` holds the `Endpoint` to check which can be used to gather knowledge about the `WebService`.
    func check(into audit: Audit, _ app: Application)
    
    /// Finish the check for the given `Audit`.
    /// This method is called once `check` has been called for all `Endpoint`s.
    func finishCheck(for audit: Audit, _ app: Application)
    
    init()
}

extension BestPractice {
    public static var priority: Priority {
        .normal
    }
    
    func check(for endpoint: AnyEndpoint, _ app: Application) -> Audit {
        let audit = Audit(endpoint, self)
        check(into: audit, app)
        return audit
    }
    
    /// Do nothing to finish the Audit by default.
    public func finishCheck(for audit: Audit, _ app: Application) { }
}

public struct BestPracticeCategories: OptionSet {
    // FUTURE complete list from Masse
    public let rawValue: Int
    
    static let urlPath          = BestPracticeCategories(rawValue: 1 << 0)
    static let httpStatusCode   = BestPracticeCategories(rawValue: 1 << 1)
    static let httpMethod       = BestPracticeCategories(rawValue: 1 << 2)
    static let parameters       = BestPracticeCategories(rawValue: 1 << 3)
    static let caching       = BestPracticeCategories(rawValue: 1 << 4)
    
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

public enum Priority: Int, Hashable {
    case high = 1, normal, low
}
