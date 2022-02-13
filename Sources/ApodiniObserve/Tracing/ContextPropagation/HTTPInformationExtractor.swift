//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniHTTP
import Instrumentation

/// An instrumentation `Extractor` that extracts values from HTTP headers from an `InformationSet` carrier.
public struct HTTPInformationExtractor: Extractor {
    public func extract(key: String, from information: InformationSet) -> String? {
        information[httpHeader: key]
    }
}
