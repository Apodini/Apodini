//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
//
// This code is based on the gRPC Swift project: https://github.com/grpc/grpc-swift
//
// SPDX-FileCopyrightText: 2019, gRPC Authors All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import NIOHPACK
import ApodiniNetworking
import ApodiniNetworkingHTTPSupport

extension AnyHTTPHeaderName {
    // value should be a single digit, i.e. in the range 0...9
    static let grpcStatus = HTTPHeaderName<Int>("grpc-status")
    static let grpcMessage = HTTPHeaderName<String>("grpc-message")
}


struct GRPCStatus: Hashable {
    let code: Code
    let message: String?
    
    /// Encodes the status (consisting of a status code and an optional status message) into the headers, replacing exixting entries if necessary.
    func encode(into headers: inout HPACKHeaders) {
        headers.remove(.grpcStatus)
        headers.remove(.grpcMessage)
        headers[.grpcStatus] = Int(code.rawValue)
        if let message = message {
            headers[.grpcMessage] = Self.percentEncode(message) ?? message
        }
    }
}


/// Having the Status conform to error allows us to return these via EventLoopFutures from rpc handlers.
extension GRPCStatus: Swift.Error {}


extension GRPCStatus {
    /// A gRPC status code, as defined in https://grpc.github.io/grpc/core/md_doc_statuscodes.html
    enum Code: UInt8 {
        /// Not an error; returned on success.
        case ok = 0
        /// The operation was cancelled, typically by the caller.
        case cancelled = 1
        /// Unknown error. For example, this error may be returned when a Status value received from another address space belongs to an error space that is not known in this address space. Also errors raised by APIs that do not return enough error information may be converted to this error.
        case unknown = 2
        /// The client specified an invalid argument. Note that this differs from FAILED_PRECONDITION. INVALID_ARGUMENT indicates arguments that are problematic regardless of the state of the system (e.g., a malformed file name).
        case invalidArgument = 3
        /// The deadline expired before the operation could complete. For operations that change the state of the system, this error may be returned even if the operation has completed successfully. For example, a successful response from a server could have been delayed long
        case deadlineExceeded = 4
        /// Some requested entity (e.g., file or directory) was not found. Note to server developers: if a request is denied for an entire class of users, such as gradual feature rollout or undocumented allowlist, NOT_FOUND may be used. If a request is denied for some users within a class of users, such as user-based access control, PERMISSION_DENIED must be used.
        case notFound = 5
        /// The entity that a client attempted to create (e.g., file or directory) already exists.
        case alreadyExists = 6
        /// The caller does not have permission to execute the specified operation. PERMISSION_DENIED must not be used for rejections caused by exhausting some resource (use RESOURCE_EXHAUSTED instead for those errors). PERMISSION_DENIED must not be used if the caller can not be identified (use UNAUTHENTICATED instead for those errors). This error code does not imply the request is valid or the requested entity exists or satisfies other pre-conditions.
        case permissionDenied = 7
        /// Some resource has been exhausted, perhaps a per-user quota, or perhaps the entire file system is out of space.
        case resourceExhausted = 8
        /// The operation was rejected because the system is not in a state required for the operation's execution. For example, the directory to be deleted is non-empty, an rmdir operation is applied to a non-directory, etc. Service implementors can use the following guidelines to decide between FAILED_PRECONDITION, ABORTED, and UNAVAILABLE: (a) Use UNAVAILABLE if the client can retry just the failing call. (b) Use ABORTED if the client should retry at a higher level (e.g., when a client-specified test-and-set fails, indicating the client should restart a read-modify-write sequence). (c) Use FAILED_PRECONDITION if the client should not retry until the system state has been explicitly fixed. E.g., if an "rmdir" fails because the directory is non-empty, FAILED_PRECONDITION should be returned since the client should not retry unless the files are deleted from the directory.
        case failedPrecondition = 9
        /// The operation was aborted, typically due to a concurrency issue such as a sequencer check failure or transaction abort. See the guidelines above for deciding between FAILED_PRECONDITION, ABORTED, and UNAVAILABLE.
        case aborted = 10
        /// The operation was attempted past the valid range. E.g., seeking or reading past end-of-file. Unlike INVALID_ARGUMENT, this error indicates a problem that may be fixed if the system state changes. For example, a 32-bit file system will generate INVALID_ARGUMENT if asked to read at an offset that is not in the range [0,2^32-1], but it will generate OUT_OF_RANGE if asked to read from an offset past the current file size. There is a fair bit of overlap between FAILED_PRECONDITION and OUT_OF_RANGE. We recommend using OUT_OF_RANGE (the more specific error) when it applies so that callers who are iterating through a space can easily look for an OUT_OF_RANGE error to detect when they are done.
        case outOfRange = 11
        /// The operation is not implemented or is not supported/enabled in this service.
        case unimplemented = 12
        /// Internal errors. This means that some invariants expected by the underlying system have been broken. This error code is reserved for serious errors.
        case `internal` = 13
        /// The service is currently unavailable. This is most likely a transient condition, which can be corrected by retrying with a backoff. Note that it is not always safe to retry non-idempotent operations.
        case unavailable = 14
        /// Unrecoverable data loss or corruption.
        case dataLoss = 15
        /// The request does not have valid authentication credentials for the operation.
        case unauthenticated = 16
    }
}


// MARK: Message Percent Encoding

extension GRPCStatus {
    /// Adds percent encoding to the given message.
    ///
    /// gRPC uses percent encoding as defined in RFC 3986 § 2.1 but with a different set of restricted
    /// characters. The allowed characters are all visible printing characters except for (`%`,
    /// `0x25`). That is: `0x20`-`0x24`, `0x26`-`0x7E`.
    ///
    /// - Parameter message: The message to encode.
    /// - Returns: Percent encoded string, or `nil` if it could not be encoded.
    private static func percentEncode(_ message: String) -> String? {
        let utf8 = message.utf8
        
        let encodedLength = self.percentEncodedLength(for: utf8)
        // Fast-path: all characters are valid, nothing to encode.
        if encodedLength == utf8.count {
            return message
        }
        
        var bytes: [UInt8] = []
        bytes.reserveCapacity(encodedLength)
        
        for char in message.utf8 {
            switch char {
            // See: https://github.com/grpc/grpc/blob/master/doc/PROTOCOL-HTTP2.md#responses
            case 0x20 ... 0x24, 0x26 ... 0x7E:
                bytes.append(char)
            default:
                bytes.append(UInt8(ascii: "%"))
                bytes.append(self.toHex(char >> 4))
                bytes.append(self.toHex(char & 0xF))
            }
        }
        return String(bytes: bytes, encoding: .utf8)
    }
    
    /// Returns the percent encoded length of the given `UTF8View`.
    private static func percentEncodedLength(for view: String.UTF8View) -> Int {
        var count = view.count
        for byte in view {
            switch byte {
            case 0x20 ... 0x24, 0x26 ... 0x7E:
                ()
            default:
                count += 2
            }
        }
        return count
    }
    
    /// Encode the given byte as hexadecimal.
    ///
    /// - Precondition: Only the four least significant bits may be set.
    /// - Parameter nibble: The nibble to convert to hexadecimal.
    private static func toHex(_ nibble: UInt8) -> UInt8 {
        assert(nibble & 0xF == nibble)
        
        switch nibble {
        case 0 ... 9:
            return nibble &+ UInt8(ascii: "0")
        default:
            return nibble &+ (UInt8(ascii: "A") &- 10)
        }
    }
}
