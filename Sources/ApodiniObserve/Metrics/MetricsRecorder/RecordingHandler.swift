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
    
    /*
    public func record(_ recordingTypes: DefaultRecordingTypes) -> DelegationModifier<Self, RecordingHandlerInitializer<OpenMetricsRecorder, Never>> {
        let closures = DefaultRecordingClosures.buildDefaultRecordingClosures(recordingTypes)
        let metricsRecorder = OpenMetricsRecorder(before: closures.0, after: closures.1, afterException: closures.2)
        
        return self.delegated(by: RecordingHandlerInitializer(recorder: metricsRecorder))
    }
     */
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
