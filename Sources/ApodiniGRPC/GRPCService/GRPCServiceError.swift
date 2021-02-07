//
//  GRPCServiceError.swift
//  
//
//  Created by Moritz Schüll on 15.01.21.
//

import Foundation

/// Errors used by `GRPCService`.
enum GRPCServiceError: Error {
    /// Thrown if user tries to register a new endpoint
    /// with a name that already is associated with an existing endpoint.
    case endpointAlreadyExists
}
