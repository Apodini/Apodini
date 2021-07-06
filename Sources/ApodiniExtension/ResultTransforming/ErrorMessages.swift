//
//  ErrorMessages.swift
//  
//
//  Created by Max Obermeier on 06.07.21.
//

import Apodini

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
    case .serverError:
        return "Unexpected Server Error"
    case .notAvailable:
        return "Resource Not Available"
    case .other:
        return "Error"
    }
}
