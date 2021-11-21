//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Logging

/// Can be used to specify what metrics schould be recorded from `Component`s
public protocol MetricsRecorder {
    /// The key of the to be used relay dictionary, defaults to a String
    associatedtype Key: Hashable = String
    /// The value of the to be used relay dictionary, defaults to a String
    associatedtype Value = String
    
    /// Recording closure that is executed before handler is executed
    var before: [RecordingClosures<Key, Value>.Before] { get }
    /// Recording closure that is executed after handler is executed (even if an exception is thrown)
    var after: [RecordingClosures<Key, Value>.After] { get }
    /// Recording closure that is executed only after handler is executed and an exception is thrown
    var afterException: [RecordingClosures<Key, Value>.AfterException] { get }
    
    /// Ability to combine (add) multiple ``MetricsRecorder`` together
    static func +<M: MetricsRecorder>(left: Self, right: M) -> Self where Self.Key == M.Key, Self.Value == M.Value
    
    /// Standardized initializer for instanciating a ``MetricsRecorder``
    /// - Parameters:
    ///   - before: The closure type of a closure which is executed before the handler is processed
    ///   - after: The closure type of a closure which is executed after the handler is processed (also in case of an exception)
    ///   - afterException: The closure type of a closure which is executed if the handler throws an exception
    init(
            before: [RecordingClosures<Key, Value>.Before],
            after: [RecordingClosures<Key, Value>.After],
            afterException: [RecordingClosures<Key, Value>.AfterException]
        )
}

/// Provide default recording closures
public extension MetricsRecorder where Self == DefaultMetricsRecorder {
    /// Records all default metrics (so responseTime, requestCounter and errorRate) from the execution of a `Handler`
    static var all: Self {
        let closures = DefaultRecordingClosures.all
        return Self(before: closures.0, after: closures.1, afterException: closures.2)
    }
    
    /// Records only the response time from the execution of a `Handler`
    static var responseTime: Self {
        let closures = DefaultRecordingClosures.responseTime
        return Self(before: closures.0, after: closures.1, afterException: closures.2)
    }
    
    /// Records only the request counter from the execution of a `Handler`
    static var requestCounter: Self {
        let closures = DefaultRecordingClosures.requestCounter
        return Self(before: closures.0, after: closures.1, afterException: closures.2)
    }
    
    /// Records only the error rate from the execution of a `Handler`
    static var errorRate: Self {
        let closures = DefaultRecordingClosures.errorRate
        return Self(before: closures.0, after: closures.1, afterException: closures.2)
    }
}

/// Allows to combine different ``MetricsRecorder``'s
public extension MetricsRecorder {
    /// Overload the + operator to simply combine different ``MetricsRecorder``'s
    static func +<M: MetricsRecorder>(left: Self, right: M) -> Self where Key == M.Key, Value == M.Value {
        Self(
            before: left.before + right.before,
            after: left.after + right.after,
            afterException: left.afterException + right.afterException
        )
    }
}

/// Serves as a default ``MetricsRecorder`` for the ``DefaultRecordingClosures``
public struct DefaultMetricsRecorder: MetricsRecorder {
    public typealias Key = String
    public typealias Value = String
    
    public var before: [RecordingClosures<Key, Value>.Before]
    public var after: [RecordingClosures<Key, Value>.After]
    public var afterException: [RecordingClosures<Key, Value>.AfterException]
    
    public init(
            before: [RecordingClosures<Key, Value>.Before] = [],
            after: [RecordingClosures<Key, Value>.After] = [],
            afterException: [RecordingClosures<Key, Value>.AfterException] = []
        ) {
        self.before = before
        self.after = after
        self.afterException = afterException
    }
}
