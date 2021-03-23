//
//  CollectedOptions.swift
//
//
//  Created by Lukas Kollmer on 2021-02-06.
//

import Foundation
import ApodiniUtils


/// A collection of deployment options
public struct CollectedOptions<OuterNS: OuterNamespace>: Codable, ExpressibleByArrayLiteral {
    public let options: [ResolvedOption<OuterNS>]
    
    public init() {
        options = []
    }
    
    public init<S>(_ options: S) where S: Sequence, S.Element == ResolvedOption<OuterNS> {
        self.options = Array(options)
    }
    
    /// - Note: this will only work if all options are in fact reducible.
    public init<S>(reducing options: S) where S: Sequence, S.Element == ResolvedOption<OuterNS> {
        self.options = Array(options.reduce(into: Set<ResolvedOption<OuterNS>>(), { options, option in
            options.insert(option) { $0.reduceOption(with: $1) }
        }))
    }
    
    public init(_ options: ResolvedOption<OuterNS>...) {
        self.init(options)
    }
    
    public init(arrayLiteral elements: ResolvedOption<OuterNS>...) {
        self.init(elements)
    }
    
    
    public func containsEntry<InnerNS, Value>(forKey optionKey: OptionKey<OuterNS, InnerNS, Value>) -> Bool {
        options.contains { $0.key == optionKey }
    }
    
    
    /// The number of options in the data structure.
    public var count: Int {
        options.count
    }
    
    
    /// Returns a copy of `self`, with all options reduced.
    /// - Note: this will only work if all options are in fact reducible.
    public func reduced() -> CollectedOptions {
        CollectedOptions(reducing: self.options)
    }
    
    
    /// - returns: the value specified for this option key, if a matching entry exists. if no matching entry exists, `nil` is returned
    /// - throws: if an entry does exist but there was an erorr reading (ie decoding) it/
    public func getValue<InnerNS, Value>(forKey optionKey: OptionKey<OuterNS, InnerNS, Value>) throws -> Value? {
        try getValue_imp(forKey: optionKey)
    }
    
    /// - returns: the value specified for this option key, if a matching entry exists. if no matching entry exists, the default value specified in the option key is returned.
    /// - throws: if an entry does exist but there was an erorr reading (ie decoding) it/
    public func getValue<InnerNS, Value>(forKey optionKey: OptionKeyWithDefaultValue<OuterNS, InnerNS, Value>) throws -> Value {
        switch try getValue_imp(forKey: optionKey) {
        case Optional<Value>.some(let value): // swiftlint:disable:this syntactic_sugar
            return value
        case .none:
            return optionKey.defaultValue
        }
    }
    
    
    /// Returns a new options object containing both the current object's options and the other object's options.
    /// Duplicate options are combined into a single entry using the option's `reduce` function.
    public func merging(with other: CollectedOptions<OuterNS>) -> CollectedOptions<OuterNS> {
        CollectedOptions(self.options + other.options)
    }
    
    
    private func getValue_imp<InnerNS, Value>(forKey optionKey: OptionKey<OuterNS, InnerNS, Value>) throws -> Value? {
        try options
            .filter { $0.key == optionKey }
            .map { try $0.readValue(as: Value.self) }
            .reduceIntoFirst { $0.reduce(with: $1) }
    }
}
