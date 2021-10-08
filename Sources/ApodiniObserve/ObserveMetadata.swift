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
    public typealias BlackboardMetadata = ObserveMetadataExporter.BlackboardObserveMetadata.BlackboardObserveMetadata
    public typealias ExporterMetadata = ExporterTypeObserveMetadata.ExporterTypeObserveMetadata
    public typealias Value = (blackboardMetadata: BlackboardMetadata, exporterMetadata: ExporterMetadata)
    
    /// Metadata from the ``Blackboard`` that is injected into the environment of the ``Handler`` via a ``Delegate``
    @Environment(\ObserveMetadataExporter.BlackboardObserveMetadata.value)
    var blackboardMetadata
    
    /// Metadata regarding the ``Exporter``type
    @Environment(\ExporterTypeObserveMetadata.value)
    var exporterMetadata
    
    @State
    private var builtBlackboardMetadata: BlackboardMetadata?
    @State
    private var builtExporterMetadata: ExporterMetadata?
    
    public init() {}
    
    public var wrappedValue: Value {
        if self.builtBlackboardMetadata == nil || self.builtExporterMetadata == nil {
            self.builtBlackboardMetadata = blackboardMetadata
            self.builtExporterMetadata = exporterMetadata
        } else {
            switch self.builtBlackboardMetadata?.communicationalPattern {
            case .clientSideStream, .bidirectionalStream:
                self.builtBlackboardMetadata = blackboardMetadata
            default: break
            }
        }
        
        guard let builtBlackboardMetadata = self.builtBlackboardMetadata,
              let builtExporterMetadata = self.builtExporterMetadata else {
            fatalError("The ObserveMetadata isn't built correctly!")
        }
        
        return (blackboardMetadata: builtBlackboardMetadata, exporterMetadata: builtExporterMetadata)
    }
}
