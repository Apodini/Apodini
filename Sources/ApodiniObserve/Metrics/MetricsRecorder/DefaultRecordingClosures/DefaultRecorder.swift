//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Logging

/// A ``DefaultRecorder`` requires to implement default closures that are executed before and after a ``Handler`` is called
public protocol DefaultRecorder {
    typealias Key = String
    typealias Value = String
    // Somehow i can't get it to work to reuse the RecordingHandler.BeforeRecordingClosure typealias
    typealias BeforeRecordingClosure = (ObserveMetadata.Value, Logger.Metadata, inout Dictionary<Key, Value>) -> Void
    typealias AfterRecordingClosure = (ObserveMetadata.Value, Logger.Metadata, Dictionary<Key, Value>) -> Void
    typealias AfterExceptionRecordingClosure = (ObserveMetadata.Value, Logger.Metadata, Error, Dictionary<Key, Value>) -> Void
    
    /// Executed before handler is executed
    static var before: BeforeRecordingClosure { get }
    /// Executed after handler is executed (even if an exception is thrown)
    static var after: AfterRecordingClosure? { get }
    /// Executed only after handler is executed and an exception is thrown
    static var afterException: AfterExceptionRecordingClosure? { get }
}

/// Default implementations of ``DefaultRecorder``
public extension DefaultRecorder {
    /// Since `after`closure will barly be used, provide a default nil for it
    static var after: AfterRecordingClosure? { nil }
    /// Since `afterException` closure will barly be used, provide a default nil for it
    static var afterException: AfterExceptionRecordingClosure? { nil }
}
