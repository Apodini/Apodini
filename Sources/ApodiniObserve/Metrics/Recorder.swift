//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Prometheus

/// A `Recorder` can be used to specify what metrics schould be recorded from `Component`s
public protocol Recorder {
    /// Executed before handler is executed
    var before: [(PrometheusClient, String) -> Void] { get }
    /// Executed after handler is executed
    var after: [(PrometheusClient, String) -> Void] { get }
    
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

public struct DefaultRecoder: Recorder {
    public var before: [(PrometheusClient, String) -> Void] = [DefaultRecordingClosures.Defaults.beforeTime]
    public var after: [(PrometheusClient, String) -> Void] = [DefaultRecordingClosures.Defaults.afterTime]
}

public enum DefaultRecordingClosures {
    public struct Defaults {
        static let beforeTime: (PrometheusClient, String) -> Void = { prometheus, handlerName in
            prometheus.createSummary(forType: Int64.self, named: handlerName).recordNanoseconds(1)
        }
        
        static let afterTime: (PrometheusClient, String) -> Void = { prometheus, handlerName in
            prometheus.createSummary(forType: Int64.self, named: handlerName).recordNanoseconds(1)
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
    public func record<R: Recorder>(_ recorder: R) -> DelegationModifier<Self, RecordingHandlerInitializer<R, Never>> {
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
    public func record<R: Recorder>(_ recorder: R) -> DelegationModifier<Self, RecordingHandlerInitializer<R, Response>> {
        self.delegated(by: RecordingHandlerInitializer(recorder: recorder))
    }
}

internal struct RecordingHandler<D, R>: Handler where D: Handler, R: Recorder {
    /// The ``Storage`` of the ``Application``
    @Environment(\.storage)
    private var storage: Storage
    
    let handler: Delegate<D>
    let recorder: Delegate<R>
    
    func handle() async throws -> D.Response {
        guard let prometheus = self.storage.get(MetricsConfiguration.MetricsStorageKey.self)?.prometheus else {
            fatalError(MetricsError.prometheusNotYetBootstrapped.rawValue)
        }
        
        let handlerInstance = try handler.instance()
        let handlerName = String(describing: type(of: handlerInstance))
        
        try recorder.instance().before.forEach { $0(prometheus, handlerName) }
        let result = try await handlerInstance.handle()
        try recorder.instance().after.forEach { $0(prometheus, handlerName) }
        
        return result
    }
}


public struct RecordingHandlerInitializer<R: Recorder, T: ResponseTransformable>: DelegatingHandlerInitializer {
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
