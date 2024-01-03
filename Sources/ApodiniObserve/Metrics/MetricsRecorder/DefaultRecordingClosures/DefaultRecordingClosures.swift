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
    /// Specialized closure type to record metrics before the `Handler` execution, utilizes by the ``DefaultRecorder``
    public typealias Before = RecordingClosures<String, String>.Before
    /// Specialized closure type to record metrics after the `Handler` execution, utilizes by the ``DefaultRecorder``
    public typealias After = RecordingClosures<String, String>.After
    /// Specialized closure type to record metrics after an exception during the `Handler` execution, utilizes by the ``DefaultRecorder``
    public typealias AfterException = RecordingClosures<String, String>.AfterException
    
    /// Builds a tupel of ``DefaultRecordingClosures`` (before, after, afterExecution)  from an arbitrary number of types of ``DefaultRecorder``'s
    /// - Parameter defaultRecorders: The ``DefaultRecorder`` types of which the ``DefaultRecordingClosures`` should be built from
    public static func buildDefaultRecordingClosures(_ defaultRecorders: [any DefaultRecorder.Type])
    -> ([DefaultRecordingClosures.Before], [DefaultRecordingClosures.After], [DefaultRecordingClosures.AfterException]) {
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
    public static func buildDefaultRecordingClosures(_ defaultRecorders: any DefaultRecorder.Type...)
    -> ([DefaultRecordingClosures.Before], [DefaultRecordingClosures.After], [DefaultRecordingClosures.AfterException]) {
        Self.buildDefaultRecordingClosures(defaultRecorders)
    }
    
    /// Builds the default `dimensions` (context information) for all Metric types
    public static let defaultDimensions: (ObserveMetadata.Value) -> [(String, String)] = { observeMetadata in
        [
            ("endpoint", observeMetadata.sharedRepositoryMetadata.endpointName),
            ("endpoint_path", String(
                    observeMetadata.sharedRepositoryMetadata.endpointPathComponents.value.reduce(into: "", { partialResult, endpointPath in
                        partialResult.append(contentsOf: endpointPath.description + "/")
                    })
                    .dropLast()
                )
            ),
            ("exporter", "\(observeMetadata.exporterMetadata.exporterType)"),
            ("operation", observeMetadata.sharedRepositoryMetadata.operation.rawValue),
            ("communication_pattern", observeMetadata.sharedRepositoryMetadata.communicationPattern.rawValue),
            ("response_type", "\(observeMetadata.sharedRepositoryMetadata.responseType.type)")
        ]
    }
}

/// Bundle ``DefaultRecorder``'s in certain categories
public extension DefaultRecordingClosures {
    /// Records all default metrics (so responseTime, requestCounter and errorRate) from the execution of a `Handler`
    static var all: ([DefaultRecordingClosures.Before],
                     [DefaultRecordingClosures.After],
                     [DefaultRecordingClosures.AfterException]) {
        Self.buildDefaultRecordingClosures(
            DefaultRecordingClosures.ResponseTime.self,
            DefaultRecordingClosures.RequestCounter.self,
            DefaultRecordingClosures.ErrorRate.self
        )
    }
    
    /// Records only the response time from the execution of a `Handler`
    static var responseTime: ([DefaultRecordingClosures.Before],
                              [DefaultRecordingClosures.After],
                              [DefaultRecordingClosures.AfterException]) {
        Self.buildDefaultRecordingClosures(
            DefaultRecordingClosures.ResponseTime.self
        )
    }
    
    /// Records only the request counter from the execution of a `Handler`
    static var requestCounter: ([DefaultRecordingClosures.Before],
                                [DefaultRecordingClosures.After],
                                [DefaultRecordingClosures.AfterException]) {
        Self.buildDefaultRecordingClosures(
            DefaultRecordingClosures.RequestCounter.self
        )
    }
    
    /// Records only the error rate from the execution of a `Handler`
    static var errorRate: ([DefaultRecordingClosures.Before],
                           [DefaultRecordingClosures.After],
                           [DefaultRecordingClosures.AfterException]) {
        Self.buildDefaultRecordingClosures(
            DefaultRecordingClosures.ErrorRate.self
        )
    }
}
