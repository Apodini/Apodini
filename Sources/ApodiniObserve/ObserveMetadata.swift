//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

/// A `DynamicProperty` that provides the raw context information within a `Handler`
/// It is used by the ``LoggingMetadata`` to provide raw context information about the execution of a `Handler`
@propertyWrapper
public struct ObserveMetadata: DynamicProperty {
    public typealias SharedRepositoryMetadata = ObserveMetadataExporter.SharedRepositoryObserveMetadata.SharedRepositoryObserveMetadata
    public typealias ExporterMetadata = ExporterTypeObserveMetadata.ExporterTypeObserveMetadata
    public typealias Value = (sharedRepositoryMetadata: SharedRepositoryMetadata, exporterMetadata: ExporterMetadata)
    
    /// Metadata from the `SharedRepository` that is injected into the environment of the `Handler` via a `Delegate`
    @Environment(\ObserveMetadataExporter.SharedRepositoryObserveMetadata.value)
    var sharedRepositoryMetadata
    
    /// Metadata regarding the `Exporter` type
    @Environment(\ExporterTypeObserveMetadata.value)
    var exporterMetadata
    
    /// Holds the built `SharedRepository` metadata
    @State
    private var builtSharedRepositoryMetadata: SharedRepositoryMetadata?
    /// Holds the built `InterfaceExporter` metadata
    @State
    private var builtExporterMetadata: ExporterMetadata?
    
    public init() {}
    
    /// Provides the metadata
    public var wrappedValue: Value {
        if self.builtSharedRepositoryMetadata == nil || self.builtExporterMetadata == nil {
            self.builtSharedRepositoryMetadata = sharedRepositoryMetadata
            self.builtExporterMetadata = exporterMetadata
        } else {
            switch self.builtSharedRepositoryMetadata?.communicationPattern {
            case .clientSideStream, .bidirectionalStream:
                self.builtSharedRepositoryMetadata = sharedRepositoryMetadata
            default: break
            }
        }
        
        guard let builtSharedRepositoryMetadata = self.builtSharedRepositoryMetadata,
              let builtExporterMetadata = self.builtExporterMetadata else {
            fatalError("The ObserveMetadata isn't built correctly!")
        }
        
        return (sharedRepositoryMetadata: builtSharedRepositoryMetadata, exporterMetadata: builtExporterMetadata)
    }
}
