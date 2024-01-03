//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// A rule capturing the inclusion and exclusion of specific ``BestPractice``s from auditing.
public protocol BestPracticeInclusionRule {
    /// Derive an action for a specific ``BestPractice`` from this inclusion rule.
    func action(for bestPractice: any BestPractice.Type) -> BestPracticeInclusionAction
}

extension BestPracticeInclusionRule {
    func apply(_ newRule: any BestPracticeInclusionRule) -> any BestPracticeInclusionRule {
        CompositeBestPracticeInclusionRule(rules: [self, newRule])
    }
}

struct BestPracticeScopeInclusionRule: BestPracticeInclusionRule {
    let scopes: BestPracticeScopes
    let action: BestPracticeInclusionAction
    
    func action(for bestPractice: any BestPractice.Type) -> BestPracticeInclusionAction {
        scopes.contains(bestPractice.scope) ? action : .noAction
    }
}

struct BestPracticeCategoryInclusionRule: BestPracticeInclusionRule {
    let categories: BestPracticeCategories
    let action: BestPracticeInclusionAction
    
    func action(for bestPractice: any BestPractice.Type) -> BestPracticeInclusionAction {
        bestPractice.category.contains(categories) ? action : .noAction
    }
}

struct SingleBestPracticeInclusionRule: BestPracticeInclusionRule {
    var action: BestPracticeInclusionAction
    var bestPractice: any BestPractice.Type
    
    func action(for bestPractice: any BestPractice.Type) -> BestPracticeInclusionAction {
        bestPractice == self.bestPractice ? action : .noAction
    }
}

/// A `CompositeBestPracticeInclusionRule` is represented by a number of inclusions and exclusions, starting from the set of all best practices
struct CompositeBestPracticeInclusionRule: BestPracticeInclusionRule {
    var rules: [any BestPracticeInclusionRule] = []
    
    mutating func apply(_ newRule: any BestPracticeInclusionRule) -> any BestPracticeInclusionRule {
        rules.append(newRule)
        return self
    }
    
    func action(for bestPractice: any BestPractice.Type) -> BestPracticeInclusionAction {
        rules.reduce(.noAction) { action, rule -> BestPracticeInclusionAction in
            let newAction = rule.action(for: bestPractice)
            if newAction == .noAction {
                return action
            } else {
                return newAction
            }
        }
    }
}

struct PassThroughInclusionRule: BestPracticeInclusionRule {
    func action(for bestPractice: any BestPractice.Type) -> BestPracticeInclusionAction {
        .noAction
    }
}

/// An action capturing whether to include, exclude or pass through ``BestPractice``s
public enum BestPracticeInclusionAction {
    /// Include the ``BestPractice``(s).
    case include
    /// Exclude the ``BestPractice``(s).
    case exclude
    /// Pass through the ``BestPractice``(s).
    case noAction
}
