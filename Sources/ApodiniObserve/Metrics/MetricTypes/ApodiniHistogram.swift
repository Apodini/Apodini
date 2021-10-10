//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Metrics

/// A wrapped version of the ``Metrics.Recorder`` of swift-metrics used as a Histrogram
@propertyWrapper
public struct ApodiniHistogram: DynamicProperty {
    @State
    private var builtHistrogram: Metrics.Recorder?
    @ObserveMetadata
    var observeMetadata
    @State
    var dimensions: [(String, String)]
    
    let label: String
    
    public init(label: String, dimensions: [(String, String)] = []) {
        self.label = label
        self._dimensions = State(wrappedValue: dimensions)
    }
    
    public var wrappedValue: Metrics.Recorder {
        if self.builtHistrogram == nil {
            self.dimensions.append(contentsOf: DefaultRecordingClosures.defaultDimensions(observeMetadata))
            self.builtHistrogram = .init(label: self.label, dimensions: self.dimensions)
        }
        
        guard let builtHistrogram = self.builtHistrogram else {
            fatalError("The Histrogram isn't built correctly!")
        }
        
        return builtHistrogram
    }
}
