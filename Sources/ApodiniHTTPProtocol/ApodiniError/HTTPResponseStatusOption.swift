//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import NIOHTTP1

extension HTTPResponseStatus: ApodiniErrorCompliantOption {
    public static func `default`(for type: ErrorType) -> HTTPResponseStatus {
        switch type {
        case .badInput:
            return .badRequest
        case .notFound:
            return .notFound
        case .unauthenticated:
            return .unauthorized
        case .forbidden:
            return .forbidden
        case .serverError:
            return .internalServerError
        case .notAvailable:
            return .serviceUnavailable
        case .other:
            return .internalServerError
        }
    }
}

extension PropertyOptionKey where PropertyNameSpace == ErrorOptionNameSpace, Option == HTTPResponseStatus {
    /// The ``PropertyOptionKey`` for ``HTTPResponseStatus`` of an ``ApodiniError``.
    public static let httpResponseStatus = PropertyOptionKey<ErrorOptionNameSpace, HTTPResponseStatus>()
}

extension AnyPropertyOption where PropertyNameSpace == ErrorOptionNameSpace {
    /// An option that holds the HTTP response status.
    public static func httpResponseStatus(_ code: HTTPResponseStatus) -> AnyPropertyOption<ErrorOptionNameSpace> {
        AnyPropertyOption(key: .httpResponseStatus, value: code)
    }
}
