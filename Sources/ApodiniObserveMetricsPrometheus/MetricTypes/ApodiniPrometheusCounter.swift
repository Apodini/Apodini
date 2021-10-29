//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniObserve
import Metrics
import Prometheus

/// A wrapped version of the ``PromCounter`` of SwiftPrometheus
/// Provides raw access to the metric types of SwiftPrometheus which are closly related to Prometheus itself, unlike swift-metrics
@propertyWrapper
public struct ApodiniPrometheusCounter<T: Numeric, U: MetricLabels>: DynamicProperty {
    @State
    private var builtCounter: PromCounter<T, U>?
    
    let label: String
    let type: T.Type
    let helpText: String?
    let initialValue: T
    let withLabelType: U.Type
    
    let prometheusLabelSanitizer: PrometheusLabelSanitizer
    
    public init(label: String,
                type: T.Type = Int64.self as! T.Type,
                helpText: String? = nil,
                initialValue: T = 0,
                withLabelType: U.Type = DimensionLabels.self as! U.Type) {
        self.label = label
        self.type = type
        self.helpText = helpText
        self.initialValue = initialValue
        self.withLabelType = withLabelType
        
        self.prometheusLabelSanitizer = PrometheusLabelSanitizer()
    }
    
    public init(label: String) where T == Int64, U == DimensionLabels {
        // Need to pass one additional value to not result in infinite recursion
        self.init(label: label, helpText: nil)
    }
    
    public var wrappedValue: PromCounter<T, U> {
        guard let prometheus = try? MetricsSystem.prometheus() else {
            fatalError(MetricsError.prometheusNotYetBootstrapped.rawValue)
        }
        
        // No need to cache the created Metric since the `createCounter()` does exactly that
        return prometheus.createCounter(
            forType: self.type,
            named: self.prometheusLabelSanitizer.sanitize(self.label),
            helpText: self.helpText,
            initialValue: self.initialValue,
            withLabelType: self.withLabelType
        )
    }
}
