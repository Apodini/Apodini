//
//  GRPCError.swift
//
//
//  Created by Moritz Schüll on 05.12.20.
//

import Foundation

/// Errors used by any GRPC specific functionality of Apodini
/// and the GRPCSemanticModelBuilder.
enum GRPCError: Error {
    /// Thrown in cases where a general Apodini functionality
    /// cannot be mapped in a sensitive way to GRPC functionality.
    case operationNotAvailable(_ message: String)
    /// Thrown if the body of a GRPC message could not
    /// be decoded successfully into the given type.
    case decodingError(_ message: String)
    /// Thrown if the content-type header of  the
    /// GRPC message indicates an unsuppored
    /// encoding format of the payload.
    case unsupportedContentType(_ message: String)
    /// Thrown if the data from the request's payload
    /// cannot be read.
    case payloadReadError(_ message: String)
}
