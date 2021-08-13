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
    
    /// Executed before handler is executed
    var before: [(ObserveMetadata.Value, Logger.Metadata, inout Dictionary<Key, Value>) -> Void] { get }
    /// Executed after handler is executed
    var after: [(ObserveMetadata.Value, Logger.Metadata, inout Dictionary<Key, Value>) -> Void] { get }
    
    //init(before: @escaping (PrometheusClient, String) -> Void, after: @escaping (PrometheusClient, String) -> Void)
    
    //init(before: [(PrometheusClient, String) -> Void], after: [(PrometheusClient, String) -> Void])
}

/*
public extension Recorder {
    init(before: @escaping (PrometheusClient) -> Void, after: @escaping (PrometheusClient) -> Void) {
        self.before.append(before)
        self.after.append(after)
    }
    
    init(before: [(PrometheusClient) -> Void], after: [(PrometheusClient) -> Void]) {
        self.before = before
        self.after = after
    }
}
 */

public struct DefaultRecoder: MetricsRecorder {
    public var before: [(ObserveMetadata.Value, Logger.Metadata, inout Dictionary<String, String>) -> Void] = [DefaultRecordingClosures.Defaults.beforeTime]
    public var after: [(ObserveMetadata.Value, Logger.Metadata, inout Dictionary<String, String>) -> Void] = [DefaultRecordingClosures.Defaults.afterTime]
}

public enum DefaultRecordingClosures {
    public struct Defaults {
        static let beforeTime: (ObserveMetadata.Value, Logger.Metadata, inout Dictionary<String, String>) -> Void = { observeMetadata, loggerMetadata, dictionary in
            let counter = Metrics.Counter(label: "asdf")
            counter.increment()
            dictionary[.init("test")] = "bla"
        }
        
        static let afterTime: (ObserveMetadata.Value, Logger.Metadata, inout Dictionary<String, String>) -> Void = { observeMetadata, loggerMetadata, dictionary in
            print(dictionary["test"])
            dictionary[.init("test2")] = "bla"
        }
    }
    
    case requestCount
    case responseTime
    case failureRate
    case all
}

extension Component {
    /// Use an asynchronous `Guard` to guard `Component`s by inspecting incoming requests
    /// - Parameter guard: The `Guard` used to inspecting incoming requests
    /// - Returns: Returns a modified `Component` protected by the asynchronous `Guard`
    public func record<R: MetricsRecorder>(_ recorder: R) -> DelegationModifier<Self, RecordingHandlerInitializer<R, Never>> {
        self.delegated(by: RecordingHandlerInitializer(recorder: recorder))
    }
    
    public func record() -> DelegationModifier<Self, RecordingHandlerInitializer<DefaultRecoder, Never>> {
        self.delegated(by: RecordingHandlerInitializer(recorder: DefaultRecoder()))
    }

    /// Resets all guards for the modified `Component`
    //public func resetGuards() -> DelegationFilterModifier<Self> {
    //    self.reset(using: GuardFilter())
    //}
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
        var dictionary = Dictionary<R.Key, R.Value>()
        
        try recorder.instance().before.forEach { $0(observeMetadata, loggingMetadata, &dictionary) }
        let result = try await handler.instance().handle()
        try recorder.instance().after.forEach { $0(observeMetadata, loggingMetadata, &dictionary) }
        
        return result
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
