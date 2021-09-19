//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Metrics

/// A wrapped version of the ``Metrics.Recorder`` of swift-metrics
@propertyWrapper
public struct Recorder: DynamicProperty {
    @State
    private var builtRecorder: Metrics.Recorder?
    @ObserveMetadata
    var observeMetadata
    @State
    var dimensions: [(String, String)]
    
    let label: String
    let aggregate: Bool
    
    public init(label: String, dimensions: [(String, String)] = [], aggregate: Bool = true) {
        self.label = label
        self._dimensions = State(wrappedValue: dimensions)
        self.aggregate = aggregate
    }
    
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
