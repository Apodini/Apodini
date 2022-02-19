//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

#if DEBUG || RELEASE_TESTING
import Instrumentation

public typealias MockCarrier = [String: String]

public struct MockCarrierExtractor: Extractor {
    public init() {}

    public func extract(key: String, from carrier: MockCarrier) -> String? {
        carrier[key]
    }
}

public struct MockCarrierInjector: Injector {
    public init() {}

    public func inject(_ value: String, forKey key: String, into carrier: inout MockCarrier) {
        carrier[key] = value
    }
}
#endif
