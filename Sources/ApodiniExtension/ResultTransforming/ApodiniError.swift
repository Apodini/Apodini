//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini

public extension ApodiniError {
    /// Create a new `ApodiniError` from its base components:
    /// - Parameter `type`: The associated `ErrorType`. If `other` is chosen, the `options` should be
    ///   used to provide additional guidance for the exporters.
    /// - Parameter `reason`: The **public** reason explaining what led to the this error.
    /// - Parameter `description`: The **internal** description of this error. This will only be exposed in `DEBUG` mode.
    /// - Parameter `options`: Possible exporter-specific options that provide guidance for how to handle this error.
    init(type: ErrorType, reason: String? = nil, description: String? = nil, _ options: Option...) {
        self = _Internal.initializeApodiniError(type: type, reason: reason, description: description, options)
    }
}

public extension Error {
    /// Returns a standard error message for this `Error` by transforming it to an
    /// `ApodiniError` and using its `.errorType` to obtain sensible message
    /// prefixes.
    var standardMessage: String {
        let error = self.apodiniError
        return error.message(with: standardMessagePrefix(for: error))
    }
    
    /// Returns a standard error message for this `Error` by transforming it to an
    /// `ApodiniError` using an empty prefix message.
    var unprefixedMessage: String {
        self.apodiniError.message(with: nil)
    }
}


private func standardMessagePrefix(for error: ApodiniError) -> String? {
    switch error.option(for: .errorType) {
    case .badInput:
        return "Bad Input"
    case .notFound:
        return "Resource Not Found"
    case .unauthenticated:
        return "Unauthenticated"
    case .forbidden:
        return "Forbidden"
    case .conflict:
        return "Conflict"
    case .preconditionFailed:
        return "Precondition Failed"
    case .serverError:
        return "Unexpected Server Error"
    case .notAvailable:
        return "Resource Not Available"
    case .other:
        return "Error"
    }
}
