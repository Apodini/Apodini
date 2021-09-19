//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Metrics

/// A wrapped version of the ``Metrics.Counter`` of swift-metrics
@propertyWrapper
public struct Counter: DynamicProperty {
    @State
    private var builtCounter: Metrics.Counter?
    @ObserveMetadata
    var observeMetadata
    @State
    var dimensions: [(String, String)]
    
    let label: String
    
    public init(label: String, dimensions: [(String, String)] = []) {
        self.label = label
        self._dimensions = State(wrappedValue: dimensions)
    }
    
    public var wrappedValue: Metrics.Counter {
        if self.builtCounter == nil {
            self.dimensions.append(contentsOf: DefaultRecordingClosures.defaultDimensions(observeMetadata))
            self.builtCounter = .init(label: self.label, dimensions: self.dimensions)
        }
        
        guard let builtCounter = self.builtCounter else {
            fatalError("The Counter isn't built correctly!")
        }
        
        return builtCounter
    }
}
