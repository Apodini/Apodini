//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Metrics

/// A wrapped version of the ``Metrics.Gauge`` of swift-metrics
@propertyWrapper
public struct ApodiniGauge: DynamicProperty {
    @State
    private var builtGauge: Metrics.Gauge?
    @ObserveMetadata
    var observeMetadata
    @State
    var dimensions: [(String, String)]
    
    let label: String
    
    public init(label: String, dimensions: [(String, String)] = []) {
        self.label = label
        self._dimensions = State(wrappedValue: dimensions)
    }
    
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
