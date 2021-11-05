//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

/// A ``DefaultRecorder`` requires to implement default closures that are executed before and after a `Handler` is called
public protocol DefaultRecorder {
    /// Executed before handler is executed
    static var before: DefaultRecordingClosures.Types.Before { get }
    /// Executed after handler is executed (even if an exception is thrown)
    static var after: DefaultRecordingClosures.Types.After? { get }
    /// Executed only after handler is executed and an exception is thrown
    static var afterException: DefaultRecordingClosures.Types.AfterException? { get }
}

/// Default implementations of ``DefaultRecorder``, so that the developer doesn't have that much of a programming code overhead when implementing a recorder.
public extension DefaultRecorder {
    /// Since `after`closure will barly be used, provide a default nil for it
    static var after: DefaultRecordingClosures.Types.After? { nil }
    /// Since `afterException` closure will barly be used, provide a default nil for it
    static var afterException: DefaultRecordingClosures.Types.AfterException? { nil }
}
