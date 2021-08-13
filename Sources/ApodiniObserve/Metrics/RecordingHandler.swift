//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Metrics
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
    
    init(before: [BeforeRecordingClosure],
         after: [AfterRecordingClosure],
         afterException: [AfterExceptionRecordingClosure])
}

/*
public struct DefaultRecoderTest: MetricsRecorder {
    public var before = [DefaultRecordingClosures.Defaults.beforeResponseTime]
    public var after = [DefaultRecordingClosures.Defaults.afterResponseTime]
    public var afterException = [DefaultRecordingClosures.Defaults.afterExceptionFailureRate]
}
 */

extension Component {
    /// Use an asynchronous `Guard` to guard `Component`s by inspecting incoming requests
    /// - Parameter guard: The `Guard` used to inspecting incoming requests
    /// - Returns: Returns a modified `Component` protected by the asynchronous `Guard`
    public func record<R: MetricsRecorder>(_ recorder: R) -> DelegationModifier<Self, RecordingHandlerInitializer<R, Never>> {
        self.delegated(by: RecordingHandlerInitializer(recorder: recorder))
    }
    
    public func record() -> DelegationModifier<Self, RecordingHandlerInitializer<MetricsRecorderDefault, Never>> {
        let closures = DefaultRecordingClosures.buildDefaultMetricsRecorder(
            defaultRecorders: DefaultRecordingClosures.ResponseTime.self,
            DefaultRecordingClosures.RequestCounter.self,
            DefaultRecordingClosures.ErrorRate.self
        )
        
        let metricsRecorder = MetricsRecorderDefault(before: closures.0, after: closures.1, afterException: closures.2)
        
        return self.delegated(by: RecordingHandlerInitializer(recorder: metricsRecorder))
    }
}

extension Handler {
    /// Use an asynchronous `Guard` to guard a `Handler` by inspecting incoming requests
    /// - Parameter guard: The `Guard` used to inspecting incoming requests
    /// - Returns: Returns a modified `Component` protected by the asynchronous `Guard`
    public func record<R: MetricsRecorder>(_ recorder: R) -> DelegationModifier<Self, RecordingHandlerInitializer<R, Response>> {
        self.delegated(by: RecordingHandlerInitializer(recorder: recorder))
    }
}

internal struct RecordingHandler<D, R>: Handler where D: Handler, R: MetricsRecorder {
    /// The ``Storage`` of the ``Application``
    @Environment(\.storage)
    private var storage: Storage
    
    /// The ``Connection``
    @Environment(\.connection)
    private var connection: Connection
    
    /// Metadata from ``BlackBoard`` and data regarding the ``Exporter`` that is injected into the environment of the ``Handler``
    @ObserveMetadata
    private var observeMetadata
    
    /// Logging metadata
    @LoggingMetadata
    private var loggingMetadata
    
    // We have access to the connection here
    
    // To provide the user (who develops the before and after functions) some kind of data, maybe get the parameters via blackboard and write it to storage of delegate (like with the logger)
    // Other kinds of data that could be used by the user? Auth related stuff, Information, ExporterType, Handler name, Parameters,
    
    let handler: Delegate<D>
    let recorder: Delegate<R>
    
    func handle() async throws -> D.Response {
        let recorderInstance = try recorder.instance()
        var dictionary = Dictionary<R.Key, R.Value>()
        
        recorderInstance.before.forEach { $0(observeMetadata, loggingMetadata, &dictionary) }
        defer {
            recorderInstance.after.forEach { $0(observeMetadata, loggingMetadata, dictionary) }
        }
        
        do {
            return try await handler.instance().handle()
        } catch {
            recorderInstance.afterException.forEach { $0(observeMetadata, loggingMetadata, error, dictionary) }
            
            throw error
        }
        
    }
}

public struct RecordingHandlerInitializer<R: MetricsRecorder, T: ResponseTransformable>: DelegatingHandlerInitializer {
    public typealias Response = T
    
    let recorder: R
    
    public func instance<D>(for delegate: D) throws -> SomeHandler<Response> where D: Handler {
        SomeHandler<Response>(RecordingHandler(handler: Delegate(delegate, .required), recorder: Delegate(self.recorder, .required)))
    }
}

/*
private protocol SomeGuardInitializer { }

extension GuardingHandlerInitializer: SomeGuardInitializer { }


struct GuardFilter: DelegationFilter {
    func callAsFunction<I>(_ initializer: I) -> Bool where I: AnyDelegatingHandlerInitializer {
        if initializer is SomeGuardInitializer {
            return false
        }
        return true
    }
}
*/
