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
