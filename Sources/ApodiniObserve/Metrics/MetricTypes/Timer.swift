//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Metrics

/// A wrapped version of the ``Metrics.Timer`` of swift-metrics
@propertyWrapper
public struct Timer: DynamicProperty {
    @State
    private var builtTimer: Metrics.Timer?
    @ObserveMetadata
    var observeMetadata
    @State
    var dimensions: [(String, String)]
    
    let label: String
    let displayUnit: TimeUnit
    
    public init(label: String, dimensions: [(String, String)] = [], preferredDisplayUnit displayUnit: TimeUnit = TimeUnit.milliseconds) {
        self.label = label
        self._dimensions = State(wrappedValue: dimensions)
        self.displayUnit = displayUnit
    }
    
    public var wrappedValue: Metrics.Timer {
        if self.builtTimer == nil {
            self.dimensions.append(contentsOf: DefaultRecordingClosures.defaultDimensions(observeMetadata))
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
