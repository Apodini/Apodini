//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Logging

/// A `Recorder` can be used to specify what metrics schould be recorded from `Component`s
public protocol MetricsRecorder {
    associatedtype Key: Hashable
    associatedtype Value
    
    typealias BeforeRecordingClosure = (ObserveMetadata.Value, Logger.Metadata, inout Dictionary<Key, Value>) -> Void
    typealias AfterRecordingClosure = (ObserveMetadata.Value, Logger.Metadata, Dictionary<Key, Value>) -> Void
    typealias AfterExceptionRecordingClosure = (ObserveMetadata.Value, Logger.Metadata, Error, Dictionary<Key, Value>) -> Void
    
    /// Executed before handler is executed
    var before: [BeforeRecordingClosure] { get }
    /// Executed after handler is executed (even if an exception is thrown)
    var after: [AfterRecordingClosure] { get }
    /// Executed only after handler is executed and an exception is thrown
    var afterException: [AfterExceptionRecordingClosure] { get }
    
    /// Ability to add multiple ``MetricsRecorder`` together
    static func +<M: MetricsRecorder>(left: Self, right: M) -> Self where Self.Key == M.Key, Self.Value == M.Value
    
    init(before: [BeforeRecordingClosure], after: [AfterRecordingClosure], afterException: [AfterExceptionRecordingClosure])
}

public extension MetricsRecorder where Self == OpenMetricsRecorder {
    static var all: Self {
        let closures = DefaultRecordingClosures.all
        return Self(before: closures.0, after: closures.1, afterException: closures.2)
    }
    
    static var responseTime: Self {
        let closures = DefaultRecordingClosures.responseTime
        return Self(before: closures.0, after: closures.1, afterException: closures.2)
    }
    
    static var requestCounter: Self {
        let closures = DefaultRecordingClosures.requestCounter
        return Self(before: closures.0, after: closures.1, afterException: closures.2)
    }
    
    static var errorRate: Self {
        let closures = DefaultRecordingClosures.errorRate
        return Self(before: closures.0, after: closures.1, afterException: closures.2)
    }
}

public extension MetricsRecorder {
    static func +<M: MetricsRecorder>(left: Self, right: M) -> Self where Key == M.Key, Value == M.Value {
        // Works without inizializer requirement
        /*
        guard let metricsRecorder = OpenMetricsRecorder(
            before: left.before + right.before,
            after: left.after + right.after,
            afterException: left.afterException + right.afterException
        ) as? Self else {
            fatalError("Not matching type in + of MetricsRecorder")
        }
        
        return metricsRecorder
         */
        
        Self.init(
            before: left.before + right.before,
            after: left.after + right.after,
            afterException: left.afterException + right.afterException
        )
    }
}


// Maybe just expose this to the developer and make MetricsRecorder internal?
open class OpenMetricsRecorder: MetricsRecorder {
    public typealias Key = String
    public typealias Value = String
    
    public var before: [BeforeRecordingClosure]
    
    public var after: [AfterRecordingClosure]
    
    public var afterException: [AfterExceptionRecordingClosure]
    
    required public init(before: [BeforeRecordingClosure] = [], after: [AfterRecordingClosure] = [], afterException: [AfterExceptionRecordingClosure] = []) {
        self.before = before
        self.after = after
        self.afterException = afterException
    }
    
    // For now this is required... (no idea why)
    /*
    public static func + <M>(left: OpenMetricsRecorder, right: M) -> OpenMetricsRecorder where M : MetricsRecorder, M.Key == String, M.Value == String {
        OpenMetricsRecorder(
            before: left.before + right.before,
            after: left.after + right.after,
            afterException: left.afterException + right.afterException
        )
    }
     */
}
