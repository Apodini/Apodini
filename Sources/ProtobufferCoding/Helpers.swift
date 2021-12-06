//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// A helper type conforming to `CodingKey` that does not support string-based coding keys,
/// and will always return the same `intValue`.
struct FixedCodingKey: CodingKey {
    /// Guaranteed to be non-nil, but has to be nullable to satisfy the `CodingKey` protocol
    let intValue: Int?
    
    init(intValue: Int) {
        self.intValue = intValue
    }
    
    init?(stringValue: String) {
        fatalError("Not supported. Provide an integer")
    }
    var stringValue: String {
        fatalError("Not supported")
    }
}
