//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import Vapor


extension Vapor.HTTPStatus {
    /// Creates a `Vapor``HTTPStatus` based on an `Apodini` `Status`.
    /// - Parameter status: The `Apodini` `Status` that should be transformed in a `Vapor``HTTPStatus`
    public init(_ status: Apodini.Status) {
        switch status {
        case .ok:
            self = .ok
        case .created:
            self = .created
        case .noContent:
            self = .noContent
        case .redirect:
            self = .seeOther
        }
    }
}
