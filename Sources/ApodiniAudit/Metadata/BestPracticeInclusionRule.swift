//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

public protocol BestPracticeInclusionRule {
    func action(for bestPractice: BestPractice.Type) -> BestPracticeInclusionAction
}

struct BestPracticeScopeInclusionRule: BestPracticeInclusionRule {
    let scopes: BestPracticeScopes
    let action: BestPracticeInclusionAction
    
    func action(for bestPractice: BestPractice.Type) -> BestPracticeInclusionAction {
        scopes.contains(bestPractice.scope) ? action : .noAction
    }
}

struct BestPracticeCategoryInclusionRule: BestPracticeInclusionRule {
    let categories: BestPracticeCategories
    let action: BestPracticeInclusionAction
    
    func action(for bestPractice: BestPractice.Type) -> BestPracticeInclusionAction {
        categories.contains(bestPractice.category) ? action : .noAction
    }
}

//extension BestPracticeScopes: BestPracticeInclusionRule {
//    func rule(for bestPractice: BestPractice.Type) -> Bool {
//        self.contains(bestPractice.scope)
//    }
//}
//
//extension BestPracticeCategories: BestPracticeInclusionRule {
//    func includes(_ bestPractice: BestPractice.Type) -> Bool {
//        self.contains(bestPractice.category)
//    }
//}

struct SingleBestPracticeInclusionRule: BestPracticeInclusionRule {
    var action: BestPracticeInclusionAction
    var bestPractice: BestPractice.Type
    
    func action(for bestPractice: BestPractice.Type) -> BestPracticeInclusionAction {
        bestPractice == self.bestPractice ? action : .noAction
    }
}

/// A `CompositeBestPracticeInclusionRule` is represented by a number of inclusions and exclusions, starting from the set of all best practices
struct CompositeBestPracticeInclusionRule: BestPracticeInclusionRule {
    var rules: [BestPracticeInclusionRule] = []
    
    mutating func apply(_ rule: BestPracticeInclusionRule) {
        rules.append(rule)
    }
    
    func action(for bestPractice: BestPractice.Type) -> BestPracticeInclusionAction {
        rules.reduce(.enable) { (action, rule) -> BestPracticeInclusionAction in
            let newAction = rule.action(for: bestPractice)
            if newAction == .noAction {
                return action
            } else {
                return newAction
            }
        }
    }
}


public enum BestPracticeInclusionAction {
    case enable, disable, noAction
}
