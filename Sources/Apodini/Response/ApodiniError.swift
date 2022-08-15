//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
    public let information: InformationSet
    private let options: PropertyOptionSet<ErrorOptionNameSpace>
    
    internal init(
        type: ErrorType,
        reason: String? = nil,
        description: String? = nil,
        information: InformationSet = [],
        _ options: PropertyOptionSet<ErrorOptionNameSpace>
    ) {
        self.options = options
        self.type = `type`
        self.reason = reason
        self.description = description
        self.information = information
    }

    /// Create a new `ApodiniError` from its base components:
    /// - Parameter `type`: The associated `ErrorType`. If `other` is chosen, the `options` should be
    ///   used to provide additional guidance for the exporters.
    /// - Parameter `reason`: The **public** reason explaining what led to the this error.
    /// - Parameter `description`: The **internal** description of this error. This will only be exposed in `DEBUG` mode.
    /// - Parameter `options`: Possible exporter-specific options that provide guidance for how to handle this error.
    internal init(type: ErrorType, reason: String? = nil, description: String? = nil, _ options: [Option] = []) {
        self.init(type: type, reason: reason, description: description, PropertyOptionSet(options))
    }
    
    /// Create a new `ApodiniError` from its base components:
    /// - Parameter `type`: The associated `ErrorType`. If `other` is chosen, the `options` should be
    ///   used to provide additional guidance for the exporters.
    /// - Parameter `reason`: The **public** reason explaining what led to the this error.
    /// - Parameter `description`: The **internal** description of this error. This will only be exposed in `DEBUG` mode.
    /// - Parameter `information`: Possible array of `Information` entries attached to the `Response`.
    /// - Parameter `options`: Possible exporter-specific options that provide guidance for how to handle this error.
    internal init(type: ErrorType, reason: String? = nil, description: String? = nil, information: AnyInformation..., options: Option...) {
        self.init(type: type, reason: reason, description: description, information: InformationSet(information), PropertyOptionSet(options))
    }

    /// Create a new `ApodiniError` from this instance using a different `reason` and/or `description`
    /// - Parameter `reason`: The **public** reason explaining what led to the this error.
    /// - Parameter `description`: The **internal** description of this error. This will only be exposed in `DEBUG` mode.
    ///   - information: If provided, it creates a union of the provided `Information` entries and the existing ones.
    ///   - options: If provided, it appends exporter-specific options to the existing ones.
    public func callAsFunction(
        reason: String? = nil,
        description: String? = nil,
        information: [AnyInformation],
        options: [Option]
    ) -> ApodiniError {
        ApodiniError(
            type: type,
            reason: preserveOriginalReasoning(new: reason, previous: self.reason, "reason"),
            description: preserveOriginalReasoning(new: description, previous: self.description, "description"),
            information: self.information.merge(with: information),
            PropertyOptionSet(lhs: self.options, rhs: options)
        )
    }
    
    /// Create a new `ApodiniError` from this instance using a different `reason` and/or `description`
    /// - Parameter `reason`: The **public** reason explaining what led to the this error.
    /// - Parameter `description`: The **internal** description of this error. This will only be exposed in `DEBUG` mode.
    ///   - information: If provided, it creates a union of the provided `Information` entries and the existing ones.
    ///   - options: If provided, it appends exporter-specific options to the existing ones.
    public func callAsFunction(
        reason: String? = nil,
        description: String? = nil,
        information: AnyInformation...,
        options: Option...
    ) -> ApodiniError {
        callAsFunction(reason: reason, description: description, information: information, options: options)
    }

    public func detailed(by error: Error) -> ApodiniError {
        detailed(by: error.apodiniError)
    }

    public func detailed(by error: ApodiniError) -> ApodiniError {
        ApodiniError(
            type: type,
            reason: preserveOriginalReasoning(new: reason, previous: error.reason, "reason"),
            description: preserveOriginalReasoning(new: description, previous: error.description, "description"),
            information: error.information.merge(with: information),
            PropertyOptionSet(lhs: error.options, rhs: options)
        )
    }

    private func preserveOriginalReasoning(new newMaybe: String?, previous previousMaybe: String?, _ name: String) -> String? {
        guard let new = newMaybe, let previous = previousMaybe else {
            return newMaybe ?? previousMaybe
        }
        return "\(new) (original \(name): \(previous)"
    }
}

extension _Internal {
    public static func initializeApodiniError(type: ErrorType,
                                              reason: String? = nil,
                                              description: String? = nil,
                                              _ options: [ApodiniError.Option]) -> ApodiniError {
        ApodiniError(type: type, reason: reason, description: description, options)
    }
}

public protocol ApodiniErrorCompliantOption: PropertyOption {
    static func `default`(for type: ErrorType) -> Self
}

extension ApodiniError {
    public func option<T: ApodiniErrorCompliantOption>(for key: OptionKey<T>) -> T {
        self.options.option(for: key) ?? T.default(for: self.type)
    }

    public func option<T: PropertyOption>(for key: OptionKey<T>) -> T? {
        self.options.option(for: key)
    }
    
    public func message(with prefix: String? = nil) -> String {
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
        self(reason: error.failureReason,
             description: error.errorDescription
                            ?? error.recoverySuggestion
                            ?? error.helpAnchor
                            ?? error.localizedDescription)
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
