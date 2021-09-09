//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

// MARK: - ResourceLocation
/// Represents distinct cases of resource locations
public enum ResourceLocation {
    /// A file `path` (`absolute` or `relative`) pointing to the resource, e.g. `.file("./path/to/main.swift")`
    case file(_ path: String)
    /// A resource stored in `bundle` with the specified `fileName` and `format`,
    /// e.g. `.resource(.module, fileName: "resource", format: .yaml)`
    case resource(_ bundle: Bundle, fileName: String, format: FileFormat)
    
    var path: String? {
        switch self {
        case let .file(localPath):
            return localPath
        case let .resource(bundle, fileName, format):
            return bundle.path(forResource: fileName, ofType: format.rawValue)
        }
    }
}

// MARK: - MigrationGuideConfigStorageKey
struct MigrationGuideConfigStorageKey: StorageKey {
    typealias Value = MigrationGuideConfiguration
}

// MARK: - MigrationGuideConfiguration
/// An object that holds export options of the Migration guide
public struct MigrationGuideConfiguration {
    let exportOptions: MigrationGuideExportOptions
    let oldDocumentPath: String?
    let migrationGuidePath: String?

    init(exportOptions: MigrationGuideExportOptions, oldDocumentPath: String? = nil, migrationGuidePath: String? = nil) {
        self.exportOptions = exportOptions
        self.oldDocumentPath = oldDocumentPath
        self.migrationGuidePath = migrationGuidePath
    }
    
    /// A convenient static function for initializing a `MigrationGuideConfiguration`` instance
    /// - Parameters:
    ///   - documentLocation: location of the API document of the previous version
    ///   - export: export options for the migration guide
    public static func compare(_ documentLocation: ResourceLocation, export: MigrationGuideExportOptions) -> Self {
        .init(exportOptions: export, oldDocumentPath: documentLocation.path)
    }
    
    /// A convenient static function for initializing a `MigrationGuideConfiguration`` instance
    /// - Parameters:
    ///   - migrationGuideLocation: location of previously generated and (potentially) adjusted migration guide
    ///   - export: export options for the migration guide
    public static func read(_ migrationGuideLocation: ResourceLocation, export: MigrationGuideExportOptions) -> Self {
        .init(exportOptions: export, migrationGuidePath: migrationGuideLocation.path)
    }
}
