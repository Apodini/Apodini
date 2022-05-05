//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

#if DEBUG || RELEASE_TESTING

@_exported import ApodiniNetworking
@_exported import NIOHTTP1
@_exported import NIOHTTP2
@_exported import NIOHPACK


// We need this as a struct in order to get the Hashable conformnace; tuples can't do that yet...
public struct XCTHTTPHeaderEntry: Hashable {
    public let name: String
    public let value: String
    
    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}


extension __ANNIOHTTPHeadersType {
    /// Maps the headers object into an array of `XCTHTTPHeaderEntry` objects.
    public func mapToXCTHeaderEntries() -> [XCTHTTPHeaderEntry] {
        self.entries.map { name, value, _ in
            XCTHTTPHeaderEntry(name: name, value: value)
        }
    }
}

#endif // DEBUG || RELEASE_TESTING
