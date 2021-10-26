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
/// A wrapped version of the `Metrics.Gauge` of swift-metrics
public struct ApodiniGauge: DynamicProperty {
    /// Holds the built `Metrics.Gauge`
    @State
    private var builtGauge: Metrics.Gauge?
    /// Holds the context information for the metric type
    @ObserveMetadata
    var observeMetadata
    /// Holds the built dimensions for the metric type
    @State
    var dimensions: [(String, String)]
    
    /// The label of the metric type
    let label: String
    
    /// Initializer for the ``ApodiniGauge``
    /// - Parameters:
    ///   - label: Label of the metric type
    ///   - dimensions: User-provided dimensions for the metirc type
    public init(label: String, dimensions: [(String, String)] = []) {
        self.label = label
        self._dimensions = State(wrappedValue: dimensions)
    }
    
    /// Holds the built `Metrics.Gauge` including the context information
    public var wrappedValue: Metrics.Gauge {
        if self.builtGauge == nil {
            self.dimensions.append(contentsOf: DefaultRecordingClosures.defaultDimensions(observeMetadata))
            self.builtGauge = .init(label: self.label, dimensions: self.dimensions)
        }
        
        guard let builtGauge = self.builtGauge else {
            fatalError("The Gauge isn't built correctly!")
        }
        
        return builtGauge
    }
}
