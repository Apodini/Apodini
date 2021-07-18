//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

//
// Created by Andreas Bauer on 03.07.21.
//

import Apodini

// MARK: InformationSet HTTP
public extension InformationSet {
    /// Returns the header value for a given HTTP header key.
    /// - Parameter key: The string name of the HTTP header to retrieve the value for.
    /// - Returns: The value of type HTTP Header, if present.
    subscript(httpHeader header: String) -> String? {
        self[HTTPHeaderKey(header)]
    }
}
