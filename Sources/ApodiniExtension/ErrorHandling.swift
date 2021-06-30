//
//  ErrorHandling.swift
//  
//
//  Created by Max Obermeier on 25.06.21.
//

import Foundation
import Apodini
import ApodiniUtils
import OpenCombine
import NIO

public protocol ErrorHandler {
    associatedtype Output
    associatedtype Failure
    
    func handle(_ error: ApodiniError) -> ErrorHandlingStrategy<Output, Failure>
}

public enum ErrorHandlingStrategy<Output, Failure> {
    case graceful(Output)
    case ignore
    case abort(Failure)
}

//public extension EventLoopFuture {
//    
//    
//}

public extension Error {
    var standardMessage: String {
        let error = self.apodiniError
        return error.message(with: standardMessagePrefix(for: error))
    }
    
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
