//
//  Throws.swift
//  
//
//  Created by Max Obermeier on 21.01.21.
//

import Foundation

/// A property wrapper that can be used on `Handler`s to obtain `ApodiniError`s.
@propertyWrapper
public struct Throws {
    private let options: PropertyOptionSet<ErrorOptionNameSpace>
    
    private let `type`: ErrorType
    
    private let reason: String?
    
    private let description: String?
    
    internal init(type: ErrorType, reason: String? = nil, description: String? = nil, _ options: [ApodiniError.Option]) {
        self.options = PropertyOptionSet(options)
        self.type = `type`
        self.reason = reason
        self.description = description
    }
    
    /// Create a new `ApodiniError` from its base components:
    /// - Parameter `type`: The associated `ErrorType`. If `other` is chosen, the `options` should be
    ///   used to provide additional guidance for the exporters.
    /// - Parameter `reason`: The **public** reason explaining what led to the this error.
    /// - Parameter `description`: The **internal** description of this error. This will only be exposed in `DEBUG` mode.
    /// - Parameter `options`: Possible exporter-specific options that provide guidance for how to handle this error.
    public init(_ type: ErrorType, reason: String? = nil, description: String? = nil, _ options: ApodiniError.Option...) {
        self.init(type: type, reason: reason, description: description, options)
    }
    
    /// An `ApodiniError` which is based on the information passed into this property wrapper. The
    /// `ApodiniError` can be called as a function to modify the errors `reason` and `description`.
    public var wrappedValue: ApodiniError {
        ApodiniError(type: self.type, reason: self.reason, description: self.description, self.options)
    }
}

extension Throws: StandardErrorContext {
    public func option<Option>(for key: PropertyOptionKey<ErrorOptionNameSpace, Option>) -> Option where Option: StandardErrorCompliantOption {
        self.options.option(for: key) ?? Option.default(for: self.type)
    }
}
