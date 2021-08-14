//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Logging

/// Specifies default RecordingClosures that can be easily extended and reused
public enum DefaultRecordingClosures {
    /// Builds a tupel of ``DefaultRecordingClosures`` (before, after, afterExecution)  from an arbitrary number of types of ``DefaultRecorder``s
    public static func buildDefaultRecordingClosures(_ defaultRecorders: [DefaultRecorder.Type])
    -> ([DefaultRecorder.BeforeRecordingClosure], [DefaultRecorder.AfterRecordingClosure], [DefaultRecorder.AfterExceptionRecordingClosure]) {
        (
            defaultRecorders.compactMap { defaultRecorder in
                defaultRecorder.before
            },
            defaultRecorders.compactMap { defaultRecorder in
                defaultRecorder.after
            },
            defaultRecorders.compactMap { defaultRecorder in
                defaultRecorder.afterException
            }
        )
    }
    
    /// Overload as variadic function
    public static func buildDefaultRecordingClosures(_ defaultRecorders: DefaultRecorder.Type...)
    -> ([DefaultRecorder.BeforeRecordingClosure], [DefaultRecorder.AfterRecordingClosure], [DefaultRecorder.AfterExceptionRecordingClosure]) {
        Self.buildDefaultRecordingClosures(defaultRecorders)
    }
    
    /// Builds the default `dimensions` of the different Metric types
    public static let defaultDimensions: (ObserveMetadata.Value) -> [(String, String)] = { observeMetadata in
        [
            ("endpoint", observeMetadata.0.endpointName),
            ("handlerType", "\(observeMetadata.0.anyEndpointSource.handlerType)"),
            ("endpointPath", observeMetadata.0.endpointPathComponents.value.reduce(into: "", { partialResult, endpointPath in
                partialResult.append(contentsOf: endpointPath.description)
            })),
            ("exporter", "\(observeMetadata.1.exporterType)"),
            ("operation", observeMetadata.0.operation.rawValue),
            ("communicationalPattern", observeMetadata.0.communicationalPattern.rawValue),
            ("responseType", "\(observeMetadata.0.responseType.type)")
        ]
    }
}

public extension DefaultRecordingClosures {
    static var all: ([DefaultRecorder.BeforeRecordingClosure], [DefaultRecorder.AfterRecordingClosure], [DefaultRecorder.AfterExceptionRecordingClosure]) {
        Self.buildDefaultRecordingClosures(
            DefaultRecordingClosures.ResponseTime.self,
            DefaultRecordingClosures.RequestCounter.self,
            DefaultRecordingClosures.ErrorRate.self
        )
    }
    
    static var responseTime: ([DefaultRecorder.BeforeRecordingClosure], [DefaultRecorder.AfterRecordingClosure], [DefaultRecorder.AfterExceptionRecordingClosure]) {
        Self.buildDefaultRecordingClosures(
            DefaultRecordingClosures.ResponseTime.self
        )
    }
    
    static var requestCounter: ([DefaultRecorder.BeforeRecordingClosure], [DefaultRecorder.AfterRecordingClosure], [DefaultRecorder.AfterExceptionRecordingClosure]) {
        Self.buildDefaultRecordingClosures(
            DefaultRecordingClosures.RequestCounter.self
        )
    }
    
    static var errorRate: ([DefaultRecorder.BeforeRecordingClosure], [DefaultRecorder.AfterRecordingClosure], [DefaultRecorder.AfterExceptionRecordingClosure]) {
        Self.buildDefaultRecordingClosures(
            DefaultRecordingClosures.ErrorRate.self
        )
    }
}
