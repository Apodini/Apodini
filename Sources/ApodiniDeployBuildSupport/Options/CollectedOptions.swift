//
//  CollectedOptions.swift
//
//
//  Created by Lukas Kollmer on 2021-02-06.
//

import Foundation



/// A collection of deployment options
public struct CollectedOptions: Codable, ExpressibleByArrayLiteral {
    public let options: [ResolvedDeploymentOption]
    
    public init() {
        options = []
    }
    
    public init<S>(_ options: S) where S: Sequence, S.Element == ResolvedDeploymentOption {
        self.options = Array(options)
    }
    
    public init<S>(reducing options: S) where S: Sequence, S.Element == ResolvedDeploymentOption {
        self.options = Array(options.reduce(into: Set<ResolvedDeploymentOption>(), { (options, option) in
            options.lk_insert(option) { $0.reduceOption(with: $1) }
        }))
    }
    
    public init(_ options: ResolvedDeploymentOption...) {
        self.init(options)
    }
    
    public init(arrayLiteral elements: ResolvedDeploymentOption...) {
        self.init(elements)
    }
    
    
    public func containsEntry<NS, Value>(forKey optionKey: OptionKey<NS, Value>) -> Bool {
        options.contains { $0.key == optionKey }
    }
    
    
    /// - returns: the value specified for this option key, if a matching entry exists. if no matching entry exists, `nil` is returned
    /// - throws: if an entry does exist but there was an erorr reading (ie decoding) it/
    public func getValue<NS, Value>(forKey optionKey: OptionKey<NS, Value>) throws -> Value? {
        try getValue_imp(forKey: optionKey)
    }
    
    /// - returns: the value specified for this option key, if a matching entry exists. if no matching entry exists, the default value specified in the option key is returned.
    /// - throws: if an entry does exist but there was an erorr reading (ie decoding) it/
    public func getValue<NS, Value>(forKey optionKey: OptionKeyWithDefaultValue<NS, Value>) throws -> Value {
        switch try getValue_imp(forKey: optionKey) {
        case Optional<Value>.some(let value):
            return value
        case .none:
            return optionKey.defaultValue
        }
    }
    
    
    /// Returns a new options object containing both the current object's options and the other object's options.
    /// Duplicate options are combined into a single entry using the option's `reduce` function.
    public func merging(with other: CollectedOptions) -> CollectedOptions {
        CollectedOptions(self.options + other.options)
    }
    
    
    private func getValue_imp<NS, Value>(forKey optionKey: OptionKey<NS, Value>) throws -> Value? {
        try options
            .filter { $0.key == optionKey }
            .map { try $0.readValue(as: Value.self) }
            .lk_reduceIntoFirst { $0.reduce(with: $1) }
    }
}
