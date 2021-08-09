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
/// A wrapped version of the ``Metrics.Recorder`` of swift-metrics used as a Histrogram
public struct MetricsHistogram: DynamicProperty {
    let label: String
    let dimensions: [(String, String)]
    
    public init(label: String, dimensions: [(String, String)]) {
        self.label = label
        self.dimensions = dimensions
    }
    
    public var wrappedValue: Metrics.Recorder {
        .init(label: self.label, dimensions: self.dimensions)
    }
}
