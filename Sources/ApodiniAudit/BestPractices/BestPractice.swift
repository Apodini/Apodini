//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

public protocol BestPractice: AnyObject {
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
    /// The default priority for a BestPractice is `.normal`.
    public static var priority: Priority {
        .normal
    }
    
    func check(for endpoint: any AnyEndpoint, _ app: Application) -> Audit {
        let audit = Audit(endpoint, self)
        check(into: audit, app)
        return audit
    }
    
    /// Do nothing to finish the Audit by default.
    public func finishCheck(for audit: Audit, _ app: Application) { }
}

public struct BestPracticeCategories: OptionSet {
    public let rawValue: Int
    
    public static let urlPath          = BestPracticeCategories(rawValue: 1 << 0)
    public static let httpStatusCode   = BestPracticeCategories(rawValue: 1 << 1)
    public static let httpMethod       = BestPracticeCategories(rawValue: 1 << 2)
    public static let parameters       = BestPracticeCategories(rawValue: 1 << 3)
    public static let caching          = BestPracticeCategories(rawValue: 1 << 4)
    public static let returnType       = BestPracticeCategories(rawValue: 1 << 5)
    
    public static let linguistic = BestPracticeCategories(rawValue: 1 << 31)
    
    public static let linguisticURL: BestPracticeCategories = [.linguistic, .urlPath]
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public struct BestPracticeScopes: OptionSet {
    public let rawValue: Int
    
    public static let http = BestPracticeScopes(rawValue: 1 << 0)
    public static let rest = BestPracticeScopes(rawValue: 1 << 1)
    
    public static let all: BestPracticeScopes = [.http, .rest]
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public enum Priority: Comparable {
    case high, normal, low
}
