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
/// A wrapped version of the ``Metrics.Recorder`` of swift-metrics
public struct MetricsRecorder: DynamicProperty {
    let label: String
    let dimensions: [(String, String)]
    let aggregate: Bool
    
    public init(label: String, dimensions: [(String, String)], aggregate: Bool) {
        self.label = label
        self.dimensions = dimensions
        self.aggregate = aggregate
    }
    
    public var wrappedValue: Metrics.Recorder {
        .init(label: self.label, dimensions: self.dimensions, aggregate: self.aggregate)
    }
}
