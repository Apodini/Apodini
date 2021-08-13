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
/// A wrapped version of the ``Metrics.Timer`` of swift-metrics
public struct Timer: DynamicProperty {
    let label: String
    let dimensions: [(String, String)]
    let displayUnit: TimeUnit
    
    public init(label: String, dimensions: [(String, String)], preferredDisplayUnit displayUnit: TimeUnit = TimeUnit.milliseconds) {
        self.label = label
        self.dimensions = dimensions
        self.displayUnit = displayUnit
    }
    
    public var wrappedValue: Metrics.Timer {
        .init(label: self.label, dimensions: self.dimensions, preferredDisplayUnit: self.displayUnit)
    }
}
