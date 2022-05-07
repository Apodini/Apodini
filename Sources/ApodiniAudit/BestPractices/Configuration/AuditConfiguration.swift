//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

public class AuditConfiguration: Configuration {
    private let bestPractices: [BestPractice]
    
    public func configure(_ app: Application) {
        // Store the best practices in the app storage
        app.storage[BestPracticesStorageKey.self] = bestPractices
    }
    
    init(
        @AuditConfigurationBuilder bestPractices: () -> [BestPractice]
    ) {
        self.bestPractices = bestPractices()
    }
}

struct BestPracticesStorageKey: StorageKey {
    typealias Value = [BestPractice]
}

public protocol BestPracticeConfiguration {
    func configureBestPractice() -> BestPractice
}

public struct EmptyBestPracticeConfiguration<BP: BestPractice>: BestPracticeConfiguration {
    public func configureBestPractice() -> BestPractice {
        BP.init()
    }
}
