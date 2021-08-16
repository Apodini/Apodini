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
    /// Use an asynchronous `Guard` to guard `Component`s by inspecting incoming requests
    /// - Parameter guard: The `Guard` used to inspecting incoming requests
    /// - Returns: Returns a modified `Component` protected by the asynchronous `Guard`
    public func record<R: MetricsRecorder>(_ recorder: R) -> DelegationModifier<Self, RecordingHandlerInitializer<R, Never>> {
        self.delegated(by: RecordingHandlerInitializer(recorder: recorder))
    }
    
    // We could also make the record function more powerful (eg. change the parameter type etc.) to spare the protocol magic
    // What if we define everything on DefaultMetricsRecorder? (s0 .all, + etc). But this wouldn't allow the combination diff recorders via + anymore
    public func record(_ recorder: DefaultMetricsRecorder = .all) -> DelegationModifier<Self, RecordingHandlerInitializer<DefaultMetricsRecorder, Never>> {
        self.delegated(by: RecordingHandlerInitializer(recorder: recorder))
    }
    
}

extension Handler {
    /// Use an asynchronous `Guard` to guard a `Handler` by inspecting incoming requests
    /// - Parameter guard: The `Guard` used to inspecting incoming requests
    /// - Returns: Returns a modified `Component` protected by the asynchronous `Guard`
    public func record<R: MetricsRecorder>(_ recorder: R) -> DelegationModifier<Self, RecordingHandlerInitializer<R, Response>> {
        self.delegated(by: RecordingHandlerInitializer(recorder: recorder))
    }
    
    public func record(_ recorder: DefaultMetricsRecorder = .all) -> DelegationModifier<Self, RecordingHandlerInitializer<DefaultMetricsRecorder, Response>> {
        self.delegated(by: RecordingHandlerInitializer(recorder: recorder))
    }
}

internal struct RecordingHandler<D, R>: Handler where D: Handler, R: MetricsRecorder {
    /// Metadata from ``BlackBoard`` and data regarding the ``Exporter`` that is injected into the environment of the ``Handler``
    @ObserveMetadata
    private var observeMetadata
    
    /// Logging metadata
    @LoggingMetadata
    private var loggingMetadata
    
    let handler: Delegate<D>
    let recorder: Delegate<R>
    
    func handle() async throws -> D.Response {
        let recorderInstance = try recorder.instance()
        var dictionary = Dictionary<R.Key, R.Value>()
        
        // TODO: Implement something that logs the incoming request
        // Maybe even pass the logger via the closures and provide a default closure that logs the information
        
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
