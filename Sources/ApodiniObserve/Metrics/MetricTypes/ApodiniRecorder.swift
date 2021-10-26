//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Metrics

@propertyWrapper
/// A wrapped version of the `Metrics.Recorder` of swift-metrics
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
    
    /// Initializer for the ``ApodiniRecorder``
    /// - Parameters:
    ///   - label: Label of the metric type
    ///   - dimensions: User-provided dimensions for the metirc type
    public init(label: String, dimensions: [(String, String)] = [], aggregate: Bool = true) {
        self.label = label
        self._dimensions = State(wrappedValue: dimensions)
        self.aggregate = aggregate
    }
    
    /// Holds the built `Metrics.Recorder` including the context information
    public var wrappedValue: Metrics.Recorder {
        if self.builtRecorder == nil {
            self.dimensions.append(contentsOf: DefaultRecordingClosures.defaultDimensions(observeMetadata))
            self.builtRecorder = .init(label: self.label, dimensions: self.dimensions, aggregate: self.aggregate)
        }
        
        guard let builtRecorder = self.builtRecorder else {
            fatalError("The Recorder isn't built correctly!")
        }
        
        return builtRecorder
    }
}
