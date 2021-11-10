//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Metrics

/// A wrapped version of the `Metrics.Recorder` of swift-metrics used as a Histrogram
@propertyWrapper
public struct ApodiniHistogram: DynamicProperty {
    /// Holds the built `Metrics.Recorder`
    @State
    private var builtHistrogram: Metrics.Recorder?
    /// Holds the context information for the metric type
    @ObserveMetadata
    var observeMetadata
    /// Holds the built dimensions for the metric type
    @State
    var dimensions: [(String, String)]
    
    /// The label of the metric type
    let label: String
    /// Indicates the level of automatically attached metadata
    let metadataLevel: MetricsMetadataLevel
    
    /// Initializer for the ``ApodiniHistogram``
    /// - Parameters:
    ///   - label: Label of the metric type
    ///   - dimensions: User-provided dimensions for the metric type
    public init(label: String, dimensions: [(String, String)] = [], metadataLevel: MetricsMetadataLevel = .all) {
        self.label = label
        self._dimensions = State(wrappedValue: dimensions)
        self.metadataLevel = metadataLevel
    }
    
    /// Holds the built `Metrics.Recorder` including the context information
    public var wrappedValue: Metrics.Recorder {
        if self.builtHistrogram == nil {
            if case .all = self.metadataLevel {
                self.dimensions.append(contentsOf: DefaultRecordingClosures.defaultDimensions(observeMetadata))
            }
            self.builtHistrogram = .init(label: self.label, dimensions: self.dimensions)
        }
        
        guard let builtHistrogram = self.builtHistrogram else {
            fatalError("The Histrogram isn't built correctly!")
        }
        
        return builtHistrogram
    }
}
