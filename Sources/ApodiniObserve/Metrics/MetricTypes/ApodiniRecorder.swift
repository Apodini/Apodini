//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Metrics

/// A wrapped version of the `Metrics.Recorder` of swift-metrics
@propertyWrapper
public struct ApodiniRecorder: DynamicProperty {
    /// Holds the built `Metrics.Recorder`
    @State
    private var builtRecorder: Metrics.Recorder?
    /// Holds the context information for the metric type
    @ObserveMetadata
    var observeMetadata
    /// Holds the built dimensions for the metric type
    @State
    var dimensions: [(String, String)]
    
    /// The label of the metric type
    let label: String
    /// The aggregation toggle of the metric type
    let aggregate: Bool
    /// Indicates the level of automatically attached metadata
    let metadataLevel: MetricsMetadataLevel
    
    /// Initializer for the ``ApodiniRecorder``
    /// - Parameters:
    ///   - label: Label of the metric type
    ///   - dimensions: User-provided dimensions for the metirc type
    public init(label: String, dimensions: [(String, String)] = [], aggregate: Bool = true, metadataLevel: MetricsMetadataLevel = .all) {
        self.label = label
        self._dimensions = State(wrappedValue: dimensions)
        self.aggregate = aggregate
        self.metadataLevel = metadataLevel
    }
    
    /// Holds the built `Metrics.Recorder` including the context information
    public var wrappedValue: Metrics.Recorder {
        if self.builtRecorder == nil {
            if case .all = self.metadataLevel {
                self.dimensions.append(contentsOf: DefaultRecordingClosures.defaultDimensions(observeMetadata))
            }
            self.builtRecorder = .init(label: self.label, dimensions: self.dimensions, aggregate: self.aggregate)
        }
        
        guard let builtRecorder = self.builtRecorder else {
            fatalError("The Recorder isn't built correctly!")
        }
        
        return builtRecorder
    }
}

public extension Metrics.Recorder {
    /// Add, change, or remove a dimension item.
    @inlinable
    subscript(dimensionsKey: String) -> String? {
        self.dimensions.first { key, _ in
            key == dimensionsKey
        }?.1
    }
}
