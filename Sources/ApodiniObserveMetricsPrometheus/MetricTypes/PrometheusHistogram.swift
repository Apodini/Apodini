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

@propertyWrapper
/// A wrapped version of the ``PromHistogram`` of SwiftPrometheus
/// Provides raw access to the metric types of SwiftPrometheus which are closly related to Prometheus itself, unlike swift-metrics
public struct PrometheusHistogram<T: DoubleRepresentable, U: HistogramLabels>: DynamicProperty {
    @State
    private var builtHistogram: PromHistogram<T, U>?
    
    let name: String
    let type: T.Type
    let helpText: String?
    let buckets: Buckets
    let withLabelType: U.Type
    
    let prometheusLabelSanitizer: PrometheusLabelSanitizer
    
    public init(_ name: String,
                type: T.Type = Int64.self as! T.Type,
                helpText: String? = nil,
                buckets: Buckets = .defaultBuckets,
                withLabelType: U.Type = DimensionHistogramLabels.self as! U.Type) {
        self.name = name
        self.type = type
        self.helpText = helpText
        self.buckets = buckets
        self.withLabelType = withLabelType
        
        self.prometheusLabelSanitizer = PrometheusLabelSanitizer()
    }
    
    public init(_ name: String) where T == Int64, U == DimensionHistogramLabels {
        // Need to pass one additional value to not result in infinite recursion
        self.init(name, helpText: nil)
    }
    
    public var wrappedValue: PromHistogram<T, U> {        
        if self.builtHistogram == nil {
            guard let prometheus = try? MetricsSystem.prometheus() else {
                fatalError(MetricsError.prometheusNotYetBootstrapped.rawValue)
            }

            self.builtHistogram = prometheus.createHistogram(
                forType: self.type,
                named: self.prometheusLabelSanitizer.sanitize(self.name),
                helpText: self.helpText,
                buckets: self.buckets,
                labels: self.withLabelType
            )
        }
        
        guard let builtHistogram = self.builtHistogram else {
            fatalError("The Histogram isn't built correctly!")
        }
        
        return builtHistogram
    }
}
