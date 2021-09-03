//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

/// An object that holds export options of API document
public struct DocumentConfiguration {
    let exportOptions: DocumentExportOptions
    
    init(exportOptions: DocumentExportOptions) {
        self.exportOptions = exportOptions
    }
    
    /// A convenient static function for initializing a `DocumentConfiguration` instance
    /// - Parameters:
    ///   - exportOptions: export options of the API Document
    public static func export(_ exportOptions: DocumentExportOptions) -> Self {
        .init(exportOptions: exportOptions)
    }
}

struct DocumentConfigStorageKey: StorageKey {
    typealias Value = DocumentConfiguration
}
