//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

public struct DocumentConfiguration {
    let exportOptions: ExportOptions
    
    init(exportOptions: ExportOptions) {
        self.exportOptions = exportOptions
    }
    
    public static func export(_ exportOptions: ExportOptions) -> Self {
        .init(exportOptions: exportOptions)
    }
}

struct DocumentConfigStorageKey: StorageKey {
    typealias Value = DocumentConfiguration
}
