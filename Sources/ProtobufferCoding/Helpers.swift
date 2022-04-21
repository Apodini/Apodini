//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// A helper type conforming to `CodingKey` that does not necessarily support string-based coding keys,
/// and will always return the same `intValue`.
struct FixedCodingKey: CodingKey {
    private let _intValue: Int
    private let _stringValue: String?
    
    init(intValue: Int) {
        self._intValue = intValue
        self._stringValue = nil
    }
    
    init(intValue: Int, stringValue: String) {
        self._intValue = intValue
        self._stringValue = stringValue
    }
    
    init?(stringValue: String) {
        fatalError("Not supported. Provide an integer")
    }
    
    /// Guaranteed to be non-nil, but has to be nullable to satisfy the `CodingKey` protocol
    var intValue: Int? { _intValue }
    /// Has to be non-nil to satisfy the `CodingKey` protocol. Will crash if there is no underlying string value.
    var stringValue: String { _stringValue! }
    
    var description: String {
        "\(Self.self)(intValue: \(_intValue), stringValue: \(_stringValue))"
    }
    
    var debugDescription: String {
        description
    }
}
