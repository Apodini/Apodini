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
/// A wrapped version of the `Metrics.Counter` of swift-metrics
public struct ApodiniCounter: DynamicProperty {
    /// Holds the built `Metrics.Counter`
    @State
    private var builtCounter: Metrics.Counter?
    /// Holds the context information for the metric type
    @ObserveMetadata
    var observeMetadata
    /// Holds the built dimensions for the metric type
    @State
    var dimensions: [(String, String)]
    
    /// The label of the metric type
    let label: String
    
    /// Initializer for the ``ApodiniCounter``
    /// - Parameters:
    ///   - label: Label of the metric type
    ///   - dimensions: User-provided dimensions for the metirc type
    public init(label: String, dimensions: [(String, String)] = []) {
        self.label = label
        self._dimensions = State(wrappedValue: dimensions)
    }
    
    /// Holds the built `Metrics.Counter` including the context information
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
