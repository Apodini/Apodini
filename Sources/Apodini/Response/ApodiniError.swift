//
//  ApodiniError.swift
//  
//
//  Created by Max Obermeier on 20.01.21.
//

import Foundation

// swiftlint:disable missing_docs
// MARK: ApodiniError

/// Generic Type that can be used to mark that the options are meant for `ApodiniError`s.
public enum ErrorOptionNameSpace { }

/// A collection of the most important error types where defaults exist for every interface exporter
public enum ErrorType: String {
    /// Error types corresponding to HTTP 4xx codes
    case badInput, notFound, unauthenticated, forbidden
    /// Error types corresponding to HTTP 5xx codes
    case serverError, notAvailable
    /// A unspecified custom error
    case other
}

/// An error that can be thrown from `Handler`s and receives special treatment from compliant interface exporters.
public struct ApodiniError: Error {
    /// Keys for options that can be used with an `ApodiniError`
    public typealias OptionKey<T: PropertyOption> = PropertyOptionKey<ErrorOptionNameSpace, T>
    /// Type erased options that can be used with an `ApodiniError`
    public typealias Option = AnyPropertyOption<ErrorOptionNameSpace>
    
    private let `type`: ErrorType
    
    private let reason: String?
    
    private let description: String?
    
    private let options: PropertyOptionSet<ErrorOptionNameSpace>
    
    internal init(type: ErrorType, reason: String? = nil, description: String? = nil, _ options: PropertyOptionSet<ErrorOptionNameSpace>) {
        self.options = options
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
    public init(type: ErrorType, reason: String? = nil, description: String? = nil, _ options: Option...) {
        self.init(type: type, reason: reason, description: description, PropertyOptionSet(options))
    }
    
    /// Create a new `ApodiniError` from this instance using a different `reason` and/or `description`
    /// - Parameter `reason`: The **public** reason explaining what led to the this error.
    /// - Parameter `description`: The **internal** description of this error. This will only be exposed in `DEBUG` mode.
    public func callAsFunction(reason: String? = nil, description: String? = nil) -> ApodiniError {
        ApodiniError(type: self.type, reason: reason ?? self.reason, description: description ?? self.description, self.options)
    }
}

public protocol ApodiniErrorCompliantOption: PropertyOption {
    static func `default`(for type: ErrorType) -> Self
}

extension ApodiniError {
    public func option<T: ApodiniErrorCompliantOption>(for key: OptionKey<T>) -> T {
        self.options.option(for: key) ?? T.default(for: self.type)
    }
    
    public func message(with prefix: String?) -> String {
        let prefix: String? = prefix?.appending(reason == nil && description == nil ? "" : ": ")
        
        #if DEBUG
        if let reason = self.reason {
            if let description = self.description {
                return (prefix ?? "") + reason + " (" + description + ")"
            } else {
                return (prefix ?? "") + reason
            }
        } else {
            if let description = self.description {
                return (prefix ?? "") + description
            } else {
                return prefix ?? "Undefined Error"
            }
        }
        #else
        if let reason = self.reason {
            return (prefix ?? "") + reason
        } else {
            return prefix ?? "Undefined Error"
        }
        #endif
    }
}

// MARK: Error Extension

public extension Error {
    var apodiniError: ApodiniError {
        if let apodiniError = self as? ApodiniError {
            return apodiniError
        } else if let localizedError = self as? LocalizedError {
            return ApodiniError(type: .other)(localizedError)
        } else {
            return ApodiniError(type: .other, description: self.localizedDescription)
        }
    }
}

extension ApodiniError {
    public func callAsFunction(_ error: LocalizedError) -> ApodiniError {
        self(reason: error.failureReason, description: error.errorDescription ?? error.recoverySuggestion ?? error.helpAnchor ?? error.localizedDescription)
    }
}

// MARK: LocalizedError Conformance

extension ApodiniError: LocalizedError {
    public var failureReason: String? {
        self.reason
    }
    
    public var errorDescription: String? {
        self.description
    }
}


// MARK: Exporter Agnostic Options

extension ErrorType: ApodiniErrorCompliantOption {
    public static func `default`(for type: ErrorType) -> Self {
        type
    }
}

public extension PropertyOptionKey where PropertyNameSpace == ErrorOptionNameSpace, Option == ErrorType {
    static let errorType = PropertyOptionKey<ErrorOptionNameSpace, ErrorType>()
}
