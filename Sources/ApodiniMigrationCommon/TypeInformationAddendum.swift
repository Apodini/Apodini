//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2022 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

public struct SwiftTypeIdentifier: RawRepresentable, Hashable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// The `TypeInformationAddendum` holds identifiers which are to be added to the respective `TypeInformation`.
public struct TypeInformationAddendum {
    /// The `TypeInformationIdentifier`s which are added to the root type.
    public var identifiers: [AnyElementIdentifier]

    /// The `TypeInformationIdentifier`s which are added to the chidlren of the respective type.
    public var childrenIdentifiers: [String: [AnyElementIdentifier]]

    /// This flag indicates if this Addendum instances was considered when building the APIDocument.
    /// We use it to check if everything was captured.
    public var queried: Bool

    init() {
        self.identifiers = []
        self.childrenIdentifiers = [:]
        self.queried = false
    }

    mutating func markingQueried() -> Self {
        self.queried = true
        return self
    }
}
