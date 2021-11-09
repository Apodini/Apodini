//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Metrics

/// A wrapped version of the `Metrics.Timer` of swift-metrics
@propertyWrapper
public struct ApodiniTimer: DynamicProperty {
    /// Holds the built `Metrics.Timer`
    @State
    private var builtTimer: Metrics.Timer?
    /// Holds the context information for the metric type
    @ObserveMetadata
    var observeMetadata
    /// Holds the built dimensions for the metric type
    @State
    var dimensions: [(String, String)]
    
    /// The label of the metric type
    let label: String
    /// The unit of the metric type
    let displayUnit: TimeUnit
    /// Indicates the level of automatically attached metadata
    let metadataLevel: MetricsMetadataLevel
    
    /// Initializer for the ``ApodiniTimer``
    /// - Parameters:
    ///   - label: Label of the metric type
    ///   - dimensions: User-provided dimensions for the metirc type
    public init(label: String,
                dimensions: [(String, String)] = [],
                preferredDisplayUnit displayUnit: TimeUnit = .milliseconds,
                metadataLevel: MetricsMetadataLevel = .all) {
        self.label = label
        self._dimensions = State(wrappedValue: dimensions)
        self.displayUnit = displayUnit
        self.metadataLevel = metadataLevel
    }
    
    /// Holds the built `Metrics.Timer` including the context information
    public var wrappedValue: Metrics.Timer {
        if self.builtTimer == nil {
            if case .all = self.metadataLevel {
                self.dimensions.append(contentsOf: DefaultRecordingClosures.defaultDimensions(observeMetadata))
            }
            self.builtTimer = .init(label: self.label,
                                    dimensions: self.dimensions,
                                    preferredDisplayUnit: self.displayUnit)
        }
        
        guard let builtTimer = self.builtTimer else {
            fatalError("The Timer isn't built correctly!")
        }
        
        return builtTimer
    }
}

public extension Metrics.Timer {
    /// Add, change, or remove a dimension item.
    @inlinable
    subscript(dimensionsKey: String) -> String? {
        self.dimensions.first { key, _ in
            key == dimensionsKey
        }?.1
    }
}
