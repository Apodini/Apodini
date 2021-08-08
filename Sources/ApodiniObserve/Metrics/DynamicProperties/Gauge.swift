//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Metrics
import Prometheus

@propertyWrapper
public struct Gauge<T: DoubleRepresentable, U: MetricLabels>: DynamicProperty {
    /// The ``Storage`` of the ``Application``
    @Environment(\.storage)
    var storage: Storage
    
    let label: String
    let type: T.Type
    let helpText: String?
    let initialValue: T
    let withLabelType: U.Type
    
    // Workaround with optional since else we can't access self.storage in the initializor
    var prometheus: PrometheusClient? = nil
    
    public init(_ label: String,
                type: T.Type = Int64.self as! T.Type,
                helpText: String? = nil,
                initialValue: T = 0,
                withLabelType: U.Type = DimensionLabels.self as! U.Type) {
        self.label = label
        self.type = type
        self.helpText = helpText
        self.initialValue = initialValue
        self.withLabelType = withLabelType
        
        if let prometheus = self.storage.get(MetricsConfiguration.MetricsStorageKey.self)?.prometheus {
            self.prometheus = prometheus
        } else {
            guard let prometheus = try? MetricsSystem.prometheus() else {
                fatalError(MetricsError.prometheusNotYetBootstrapped.rawValue)
            }
            
            self.prometheus = prometheus
        }
    }
    
    public init(_ label: String) {
        self.init(label, helpText: nil)
    }
    
    public var wrappedValue: PromGauge<T, U> {
        guard let prometheus = self.prometheus else {
            fatalError(MetricsError.metricAccessedBeforeBeeingInitialized.rawValue)
        }

        return prometheus.createGauge(
            forType: self.type,
            named: self.label,
            helpText: self.helpText,
            initialValue: self.initialValue,
            withLabelType: self.withLabelType
        )
    }
}
