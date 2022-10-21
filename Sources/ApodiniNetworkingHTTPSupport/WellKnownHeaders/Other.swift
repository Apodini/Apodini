//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


import Foundation
import NIOHTTP1


public extension AnyHTTPHeaderName {
    /// The `Accept` HTTP header field
    static let accept = HTTPHeaderName<[HTTPMediaType]>("Accept")
    /// The `Content-Type` HTTP header field
    static let contentType = HTTPHeaderName<HTTPMediaType>("Content-Type")
    /// The `Date` HTTP header field
    static let date = HTTPHeaderName<Date>("Date")
    /// The `Server` HTTP header field
    static let server = HTTPHeaderName<String>("Server")
    /// The `Content-Length` HTTP header field
    static let contentLength = HTTPHeaderName<Int>("Content-Length")
}


extension String: HTTPHeaderFieldValueCodable {
    public init?(httpHeaderFieldValue value: String) {
        self = value
    }

    public func encodeToHTTPHeaderFieldValue() -> String {
        self
    }
}


extension Int: HTTPHeaderFieldValueCodable {
    public init?(httpHeaderFieldValue value: String) {
        self.init(value)
    }

    public func encodeToHTTPHeaderFieldValue() -> String {
        String(self)
    }
}


extension Date: HTTPHeaderFieldValueCodable {
    private static let httpDateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(identifier: "GMT")!
        fmt.dateFormat = "EEE',' dd' 'MMM' 'yyyy HH':'mm':'ss zzz"
        return fmt
    }()

    public init?(httpHeaderFieldValue value: String) {
        if let date = Self.httpDateFormatter.date(from: value) {
            self = date
        } else {
            return nil
        }
    }

    public func encodeToHTTPHeaderFieldValue() -> String {
        Self.httpDateFormatter.string(from: self)
    }
}


extension Array: HTTPHeaderFieldValueCodable where Element: HTTPHeaderFieldValueCodable {
    public init?(httpHeaderFieldValue value: String) {
        fatalError("Decode \(Self.self) through the \(HTTPHeaders.self) API, rather than this initializer.")
    }

    public func encodeToHTTPHeaderFieldValue() -> String {
        fatalError("Encode \(Self.self) through the \(HTTPHeaders.self) API, rather than this method.")
    }
}
