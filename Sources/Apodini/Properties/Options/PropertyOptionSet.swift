//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation


/// A `PropertyOptionSet` collects different type erased `PropertyOptionKey`s.
struct PropertyOptionSet<Property> {
    private var options: [AnyPropertyOptionKey: Any]

    init() {
        options = [:]
    }

    init(_ options: [AnyPropertyOption<Property>]) {
        var combined: [AnyPropertyOptionKey: Any] = [:]
        for option in options {
            if let lhs = combined[option.key] {
                combined[option.key] = option.key.combine(lhs: lhs, rhs: option.value)
            } else {
                combined[option.key] = option.value
            }
        }

        self.options = combined
    }


    func option<Option>(for key: PropertyOptionKey<Property, Option>) -> Option? {
        guard let option = options[key] as? Option else {
            return nil
        }
        
        return option
    }
    
    mutating func addOption<Option>(_ option: Option, for key: PropertyOptionKey<Property, Option>) {
        if let lhs = options[key] {
            options[key] = key.combine(lhs: lhs, rhs: option)
        } else {
            options[key] = option
        }
    }
}
