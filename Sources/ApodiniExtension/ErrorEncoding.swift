//
//  ErrorEncoding.swift
//  
//
//  Created by Max Obermeier on 25.06.21.
//

import Foundation
import Apodini
import ApodiniUtils

public extension Error {
    var standardMessage: String {
        let error = self.apodiniError
        return error.message(with: standardMessagePrefix(for: error))
    }
}


private func standardMessagePrefix(for error: StandardErrorContext) -> String? {
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
