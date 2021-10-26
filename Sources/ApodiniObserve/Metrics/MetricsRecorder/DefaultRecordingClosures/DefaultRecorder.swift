//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Logging

/// A ``DefaultRecorder`` requires to implement default closures that are executed before and after a `Handler` is called
public protocol DefaultRecorder {
    /// The key of the relay dictionary, defaults to a String
    typealias Key = String
    /// The value of the relay dictionary, defaults to a String
    typealias Value = String
    /// The closure type of a default closure which is executed before the handler is processed
    typealias BeforeRecordingClosure = (ObserveMetadata.Value, Logger.Metadata, inout [Key: Value]) -> Void
    /// The closure type of a default closure which is executed after the handler is processed (also in case of an exception)
    typealias AfterRecordingClosure = (ObserveMetadata.Value, Logger.Metadata, [Key: Value]) -> Void
    /// The closure type of a default closure which is executed if the handler throws an exception
    typealias AfterExceptionRecordingClosure = (ObserveMetadata.Value, Logger.Metadata, Error, [Key: Value]) -> Void
    
    /// Executed before handler is executed
    static var before: BeforeRecordingClosure { get }
    /// Executed after handler is executed (even if an exception is thrown)
    static var after: AfterRecordingClosure? { get }
    /// Executed only after handler is executed and an exception is thrown
    static var afterException: AfterExceptionRecordingClosure? { get }
}

/// Default implementations of ``DefaultRecorder``, so that the developer doesn't have that much of an programming code overhead while implementing a recoreder
public extension DefaultRecorder {
    /// Since `after`closure will barly be used, provide a default nil for it
    static var after: AfterRecordingClosure? { nil }
    /// Since `afterException` closure will barly be used, provide a default nil for it
    static var afterException: AfterExceptionRecordingClosure? { nil }
}
