//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation

/// Errors used by `GRPCService`.
enum GRPCServiceError: Error {
    /// Thrown if user tries to register a new endpoint
    /// with a name that already is associated with an existing endpoint.
    case endpointAlreadyExists
}
