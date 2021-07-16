//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
