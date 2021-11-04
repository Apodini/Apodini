//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable large_tuple

/// Specifies default RecordingClosures that can be easily extended and reused
public enum DefaultRecordingClosures {
    /// Builds a tupel of ``DefaultRecordingClosures`` (before, after, afterExecution)  from an arbitrary number of types of ``DefaultRecorder``'s
    /// - Parameter defaultRecorders: The ``DefaultRecorder`` types of which the ``DefaultRecordingClosures`` should be built from
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
    
    /// Builds a tupel of ``DefaultRecordingClosures`` (before, after, afterExecution)  from an arbitrary number of types of ``DefaultRecorder``'s (overload as a variadic function)
    /// - Parameter defaultRecorders: The ``DefaultRecorder`` types of which the ``DefaultRecordingClosures`` should be built from
    public static func buildDefaultRecordingClosures(_ defaultRecorders: DefaultRecorder.Type...)
    -> ([DefaultRecorder.BeforeRecordingClosure], [DefaultRecorder.AfterRecordingClosure], [DefaultRecorder.AfterExceptionRecordingClosure]) {
        Self.buildDefaultRecordingClosures(defaultRecorders)
    }
    
    /// Builds the default `dimensions` (context information) for all Metric types
    public static let defaultDimensions: (ObserveMetadata.Value) -> [(String, String)] = { observeMetadata in
        [
            ("endpoint", observeMetadata.blackboardMetadata.endpointName),
            ("endpoint_path", String(observeMetadata.blackboardMetadata.endpointPathComponents.value.reduce(into: "", { partialResult, endpointPath in
                partialResult.append(contentsOf: endpointPath.description + "/")
            })
            .dropLast())),
            ("exporter", "\(observeMetadata.exporterMetadata.exporterType)"),
            ("operation", observeMetadata.blackboardMetadata.operation.rawValue),
            ("communicational_pattern", observeMetadata.blackboardMetadata.communicationalPattern.rawValue),
            ("service_type", observeMetadata.blackboardMetadata.serviceType.rawValue),
            ("response_type", "\(observeMetadata.blackboardMetadata.responseType.type)")
        ]
    }
}

/// Bundle ``DefaultRecorder``'s in certain categories
public extension DefaultRecordingClosures {
    /// Records all default metrics (so responseTime, requestCounter and errorRate) from the execution of a `Handler`
    static var all: ([DefaultRecorder.BeforeRecordingClosure],
                     [DefaultRecorder.AfterRecordingClosure],
                     [DefaultRecorder.AfterExceptionRecordingClosure]) {
        Self.buildDefaultRecordingClosures(
            DefaultRecordingClosures.ResponseTime.self,
            DefaultRecordingClosures.RequestCounter.self,
            DefaultRecordingClosures.ErrorRate.self
        )
    }
    
    /// Records only the response time from the execution of a `Handler`
    static var responseTime: ([DefaultRecorder.BeforeRecordingClosure],
                              [DefaultRecorder.AfterRecordingClosure],
                              [DefaultRecorder.AfterExceptionRecordingClosure]) {
        Self.buildDefaultRecordingClosures(
            DefaultRecordingClosures.ResponseTime.self
        )
    }
    
    /// Records only the request counter from the execution of a `Handler`
    static var requestCounter: ([DefaultRecorder.BeforeRecordingClosure],
                                [DefaultRecorder.AfterRecordingClosure],
                                [DefaultRecorder.AfterExceptionRecordingClosure]) {
        Self.buildDefaultRecordingClosures(
            DefaultRecordingClosures.RequestCounter.self
        )
    }
    
    /// Records only the error rate from the execution of a `Handler`
    static var errorRate: ([DefaultRecorder.BeforeRecordingClosure],
                           [DefaultRecorder.AfterRecordingClosure],
                           [DefaultRecorder.AfterExceptionRecordingClosure]) {
        Self.buildDefaultRecordingClosures(
            DefaultRecordingClosures.ErrorRate.self
        )
    }
}
