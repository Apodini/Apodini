//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

public struct SelectBestPracticesMetadata: ComponentMetadataDefinition {
    public typealias Key = BestPracticeContextKey
    
    public let value: BestPracticeInclusionRule
    
    public init(_ action: BestPracticeInclusionAction, _ categories: BestPracticeCategories) {
        self.value = BestPracticeCategoryInclusionRule(categories: categories, action: action)
    }
    
    public init(_ action: BestPracticeInclusionAction, _ scopes: BestPracticeScopes) {
        self.value = BestPracticeScopeInclusionRule(scopes: scopes, action: action)
    }
    
    public init(_ action: BestPracticeInclusionAction, _ bestPractice: BestPractice.Type) {
        self.value = SingleBestPracticeInclusionRule(action: action, bestPractice: bestPractice)
    }
}

public struct BestPracticeContextKey: ContextKey {
    public typealias Value = BestPracticeInclusionRule
    
    static public var defaultValue: BestPracticeInclusionRule = PassThroughInclusionRule()
    
    public static func reduce(value: inout BestPracticeInclusionRule, nextValue: BestPracticeInclusionRule) {
        value = value.apply(nextValue)
    }
}

public extension ComponentMetadataNamespace {
    typealias SelectBestPractices = SelectBestPracticesMetadata
}
