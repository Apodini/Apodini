//
// Created by Andreas Bauer on 03.07.21.
//

import Apodini
import Vapor

extension Vapor.HTTPStatus {
    /// Creates a `Vapor``HTTPStatus` based on an `Apodini` `ErrorType`.
    /// - Parameter status: The `Apodini` `ErrorType` that should be transformed in a `Vapor``HTTPStatus`
    public init(_ error: Apodini.ErrorType) {
        switch error {
        case .badInput:
             self = .badRequest
        case .notFound:
            self = .notFound
        case .unauthenticated:
            self = .unauthorized
        case .forbidden:
            self = .forbidden
        case .serverError:
            self = .internalServerError
        case .notAvailable:
            self = .serviceUnavailable
        case .other:
            self = .internalServerError
        }
    }
}
