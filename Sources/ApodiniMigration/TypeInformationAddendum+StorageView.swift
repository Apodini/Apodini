//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2022 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import ApodiniMigrationCommon
import ApodiniMigratorCore

extension SwiftTypeIdentifier {
    init(from typeName: TypeName) {
        // we recreate the output of String(reflecting:) here
        self.init(rawValue: typeName.buildName(
            printTargetName: true,
            componentSeparator: ".",
            genericsStart: "<",
            genericsSeparator: ",",
            genericsDelimiter: ">"
        ))
    }
}

extension TypeInformationAddendum {
    struct StorageView: TypeIdentifiersDescription {
        let identifiers: ElementIdentifierStorage

        let childrenIdentifiers: [String: ElementIdentifierStorage]

        fileprivate init(from addendum: TypeInformationAddendum) {
            var storage = ElementIdentifierStorage()
            for identifier in addendum.identifiers {
                storage.add(anyIdentifier: identifier)
            }
            self.identifiers = storage

            self.childrenIdentifiers = addendum.childrenIdentifiers
                .map { key, value -> (key: String, storage: ElementIdentifierStorage) in
                    var storage = ElementIdentifierStorage()
                    for identifier in value {
                        storage.add(anyIdentifier: identifier)
                    }

                    return (key, storage)
                }
                .reduce(into: [:]) { result, element in
                    result[element.key] = element.storage
                }
        }
    }
}

extension ApodiniMigrationContext {
    func retrieveTypeInformationAddendum(for typeName: TypeName) -> TypeInformationAddendum.StorageView? {
        guard let addendum = self.retrieveTypeInformationAddendum(for: SwiftTypeIdentifier(from: typeName)) else {
            return nil
        }

        return TypeInformationAddendum.StorageView(from: addendum)
    }
}
