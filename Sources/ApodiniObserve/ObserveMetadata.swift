//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

@propertyWrapper
public struct ObserveMetadata: DynamicProperty {
    public typealias Value = (ObserveMetadataExporter.BlackboardObserveMetadata.BlackboardObserveMetadata,
                              ExporterTypeObserveMetadata.ExporterTypeObserveMetadata)
    
    /// Metadata from the ``Blackboard`` that is injected into the environment of the ``Handler`` via a ``Delegate``
    @Environment(\ObserveMetadataExporter.BlackboardObserveMetadata.value)
    var blackboardMetadata
    
    /// Metadata regarding the ``Exporter``type
    @Environment(\ExporterTypeObserveMetadata.value)
    var exporterMetadata
    
    @State
    private var builtMetadata: Value?
    
    public var wrappedValue: Value {
        if self.builtMetadata == nil {
            self.builtMetadata = (self.blackboardMetadata, self.exporterMetadata)
        }
        
        guard let builtMetadata = self.builtMetadata else {
            fatalError("The ObserveMetadata isn't built correctly!")
        }
        
        return builtMetadata
    }
    
    public init() {}
}