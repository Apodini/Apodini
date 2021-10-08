//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Logging

extension Component {
    /// Use a`MetricsRecorder` to record metrics from an incoming request of a `Component`
    /// - Parameter recorder: The `MetricsRecorder` used to record metrics from an incoming request
    /// - Returns: Returns a modified `Component` wrapped by the `MetricsRecorder`
    public func record<R: MetricsRecorder>(_ recorder: R) -> DelegationModifier<Self, RecordingHandlerInitializer<R, Never>> {
        self.delegated(by: RecordingHandlerInitializer(recorder: recorder))
    }
    
    /// Use a `DefaultMetricsRecorder` to record default metrics from an incoming request of a `Component`
    /// - Parameter recorder: The `MetricsRecorder` used to record default metrics from an incoming request, defaults to `.all`
    /// - Returns: Returns a modified `Component` wrapped by the `MetricsRecorder`
    public func record(_ recorder: DefaultMetricsRecorder = .all)
    -> DelegationModifier<Self, RecordingHandlerInitializer<DefaultMetricsRecorder, Never>> {
        self.delegated(by: RecordingHandlerInitializer(recorder: recorder))
    }
}

extension Handler {
    /// Use a`MetricsRecorder` to record metrics from an incoming request of a `Component`
    /// - Parameter recorder: The `MetricsRecorder` used to record metrics from an incoming request
    /// - Returns: Returns a modified `Component` wrapped by the `MetricsRecorder`
    public func record<R: MetricsRecorder>(_ recorder: R) -> DelegationModifier<Self, RecordingHandlerInitializer<R, Response>> {
        self.delegated(by: RecordingHandlerInitializer(recorder: recorder))
    }
    
    /// Use a `DefaultMetricsRecorder` to record default metrics from an incoming request of a `Component`
    /// - Parameter recorder: The `MetricsRecorder` used to record default metrics from an incoming request, defaults to `.all`
    /// - Returns: Returns a modified `Component` wrapped by the `MetricsRecorder`
    public func record(_ recorder: DefaultMetricsRecorder = .all)
    -> DelegationModifier<Self, RecordingHandlerInitializer<DefaultMetricsRecorder, Response>> {
        self.delegated(by: RecordingHandlerInitializer(recorder: recorder))
    }
}

internal struct RecordingHandler<D, R>: Handler where D: Handler, R: MetricsRecorder {
    @ApodiniLogger
    private var logger
    
    let handler: Delegate<D>
    let recorder: Delegate<R>
    
    func handle() async throws -> D.Response {
        let recorderInstance = try recorder.instance()
        var dictionary = [R.Key: R.Value]()
        
        let loggingMetadata = _logger.loggingMetadata
        let observeMetadata = _logger.observeMetadata
        
        logger.info("Incoming request for endpoint \(observeMetadata.blackboardMetadata.endpointName) via \(String(describing: observeMetadata.exporterMetadata.exporterType))")
        
        // Execute "before" and defer "after" recording closures
        recorderInstance.before.forEach { $0(observeMetadata, loggingMetadata, &dictionary) }
        defer {
            recorderInstance.after.forEach { $0(observeMetadata, loggingMetadata, dictionary) }
        }
        
        do {
            return try await handler.instance().handle()
        } catch {
            // Execute "after exception" recording closures
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
