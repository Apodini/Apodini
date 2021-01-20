//
//  ApodiniError.swift
//  
//
//  Created by Max Obermeier on 20.01.21.
//

import Foundation

// MARK: ApodiniError

/// Generic Type that can be used to mark that the options are meant for `ApodiniError`s.
public enum ErrorOptionNameSpace { }

/// A collection of the most important error types where defaults exist for every interface exporter
public enum ErrorType: String {
    /// Error types correspoinding to HTTP 4xx codes
    case badInput, notFound, unauthenticated, forbidden
    /// Error types correspoinding to HTTP 5xx codes
    case `internal`, notAvailable
}

/// An error that can be returned from `Handler`s and receives special treatment from compliant interface exporters.
public struct ApodiniError: Error {
    /// Keys for options that can be used with an `ApodiniError`
    public typealias OptionKey<T: PropertyOption> = PropertyOptionKey<ErrorOptionNameSpace, T>
    /// Type erased options that can be used with an `ApodiniError`
    public typealias Option = AnyPropertyOption<ErrorOptionNameSpace>
    
    private let options: PropertyOptionSet<ErrorOptionNameSpace>
    
    internal let `type`: ErrorType?
    
    private let reason: String?
    
    private let description: String?
    
    
    internal init(type: ErrorType?, reason: String? = nil, description: String? = nil, _ options: [Option]) {
        self.options = PropertyOptionSet(options)
        self.type = `type`
        self.reason = reason
        self.description = description
    }
    
    /// Create a new `ApodiniError` from its base components:
    /// - Parameter `type`: The associated `ErrorType`. If none is provided, the `options` should be used to provide
    ///   additional guidance for the exporters.
    /// - Parameter `reason`: The **public** reason explaining what led to the this error.
    /// - Parameter `description`: The **internal** description of this error. This will only be exposed in `DEBUG` mode.
    /// - Parameter `options`: Possible exporter-specific options that provide guidance for how to handle this error.
    public init(type: ErrorType?, reason: String? = nil, description: String? = nil, _ options: Option...) {
        self.init(type: type, reason: reason, description: description, options)
    }
}

// MARK: StandardError

protocol StandardErrorCompliantOption: PropertyOption {
    static func `default`(for type: ErrorType?) -> Self
}

protocol StandardErrorCompliantExporter: InterfaceExporter {
    static func messagePrefix(for error: StandardError) -> String
}

protocol StandardError: Error {
    func option<Option: StandardErrorCompliantOption>(for key: PropertyOptionKey<ErrorOptionNameSpace, Option>) -> Option
    
    func message<E: StandardErrorCompliantExporter>(for exporter: E.Type) -> String
}

extension ApodiniError: StandardError {
    func option<T: StandardErrorCompliantOption>(for key: OptionKey<T>) -> T {
        if let option = self.options.option(for: key) {
            return option
        }
        
        return T.default(for: self.type)
    }
    
    func message<E: StandardErrorCompliantExporter>(for exporter: E.Type) -> String {
        let prefix = E.messagePrefix(for: self)
        
        #if DEBUG
        if let reason = self.reason {
            if let description = self.description {
                return prefix + ": " + reason + "(" + description + ")"
            } else {
                return prefix + ": " + reason
            }
        } else {
            if let description = self.description {
                return prefix + ": " + description
            } else {
                return prefix
            }
        }
        #else
        if let reason = self.reason {
            return prefix + ": " + reason
        } else {
            return prefix
        }
        #endif
    }
}

// MARK: Error Extension

internal extension Error {
    var apodiniError: ApodiniError {
        ApodiniError(type: nil, description: self.localizedDescription)
    }
}

// MARK: CustomDebugStringConvertible

extension ApodiniError: CustomDebugStringConvertible {
    public var debugDescription: String {
        var reasonString = ""
        if let reason = self.reason {
            reasonString = ", reason: \"\(reason)\""
        }
        
        var descriptionString = ""
        if let description = self.description {
            descriptionString = ", description: \"\(description)\""
        }
        
        var optionString = ""
        if options.isEmpty {
            optionString = ", options: " + options.debugDescription
        }
        
        return "ApodiniError(type: \(self.type?.rawValue ?? "")\(reasonString)\(descriptionString)\(optionString))"
    }
}
