//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

struct MigrationGuideConfigStorageKey: StorageKey {
    typealias Value = MigrationGuideConfiguration
}

public struct MigrationGuideConfiguration {
    let exportOptions: ExportOptions
    
    let oldDocumentPath: String?
    let migrationGuidePath: String?

    init(exportOptions: ExportOptions, oldDocumentPath: String? = nil, migrationGuidePath: String? = nil) {
        self.exportOptions = exportOptions
        self.oldDocumentPath = oldDocumentPath
        self.migrationGuidePath = migrationGuidePath
    }
    
    public static func compare(_ documentLocation: ResourceLocation, export: ExportOptions) -> Self {
        return .init(exportOptions: export, oldDocumentPath: documentLocation.path)
    }
    
    public static func read(_ migrationGuideLocation: ResourceLocation, export: ExportOptions) -> Self {
        return .init(exportOptions: export, migrationGuidePath: migrationGuideLocation.path)
    }
}
