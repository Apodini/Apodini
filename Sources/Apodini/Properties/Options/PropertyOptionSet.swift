//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation


/// A `PropertyOptionSet` collects different type erased `PropertyOptionKey`s.
public struct PropertyOptionSet<Property> {
    private var options: [AnyPropertyOptionKey: Any]

    public var count: Int {
        options.count
    }

    public init() {
        options = [:]
    }

    internal init(_ options: [AnyPropertyOption<Property>]) {
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

    /// Initializes a new ``PropertyOptionSet`` by providing a Option value and the corresponding key.
    /// - Parameters:
    ///   - option: The option value.
    ///   - key: The corresponding option value in the given namespace.
    public init<Option>(_ option: Option, for key: PropertyOptionKey<Property, Option>) {
        self.init()
        self.addOption(option, for: key)
    }


    public func option<Option>(for key: PropertyOptionKey<Property, Option>) -> Option? {
        guard let option = options[key] as? Option else {
            return nil
        }
        
        return option
    }

    public func option<Option: PropertyOptionWithDefault>(for key: PropertyOptionKey<Property, Option>) -> Option {
        guard let option = options[key] as? Option else {
            return Option.defaultValue
        }

        return option
    }
    
    public mutating func addOption<Option>(_ option: Option, for key: PropertyOptionKey<Property, Option>) {
        if let lhs = options[key] {
            options[key] = key.combine(lhs: lhs, rhs: option)
        } else {
            options[key] = option
        }
    }

    public func addingOption<Option>(_ option: Option, for key: PropertyOptionKey<Property, Option>) -> PropertyOptionSet<Property> {
        var instance = self
        instance.addOption(option, for: key)
        return instance
    }
}

public extension PropertyOptionSet {
    init(lhs: PropertyOptionSet<Property>, rhs: [AnyPropertyOption<Property>]) {
        self.options = lhs.options

        for option in rhs {
            if let lhsOption = options[option.key] {
                options[option.key] = option.key.combine(lhs: lhsOption, rhs: option.value)
            } else {
                options[option.key] = option.value
            }
        }
    }

    init(lhs: PropertyOptionSet<Property>, rhs: PropertyOptionSet<Property>) {
        self.options = lhs.options

        self.merge(withRHS: rhs)
    }

    mutating func merge(withRHS optionSet: PropertyOptionSet<Property>) {
        for (key, value) in optionSet.options {
            if let lhsOption = options[key] {
                options[key] = key.combine(lhs: lhsOption, rhs: value)
            } else {
                options[key] = value
            }
        }
    }
}
