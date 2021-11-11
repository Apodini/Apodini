//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import ApodiniExtension
import ApodiniHTTPProtocol
import ApodiniLoggingSupport
import Vapor
import Foundation

extension Vapor.Request: RequestBasis {
    public var debugDescription: String {
        "Vapor.Request: \(self.description)"
    }

    public var information: InformationSet {
        InformationSet(headers.map { key, rawValue in
            AnyHTTPInformation(key: key, rawValue: rawValue)
        }).merge(with: self.loggingMetadata)
    }
    
    var loggingMetadata: [LoggingMetadataInformation] {
         [
            LoggingMetadataInformation(key: .init("HTTPBody"), rawValue: .string(self.bodyData.count < 32_768 ? String(decoding: self.bodyData, as: UTF8.self) : "\(String(decoding: self.bodyData, as: UTF8.self).prefix(32_715))... (further bytes omitted since HTTP body too large!")),
            LoggingMetadataInformation(key: .init("HTTPContentType"), rawValue: .string(self.content.contentType?.description ?? "unknown")),
            LoggingMetadataInformation(key: .init("hasSession"), rawValue: .string(self.hasSession.description)),
            LoggingMetadataInformation(key: .init("route"), rawValue: .string(self.route?.description ?? "unknown")),
            LoggingMetadataInformation(key: .init("HTTPVersion"), rawValue: .string(self.version.description)),
            LoggingMetadataInformation(key: .init("url"), rawValue: .string(self.url.description))
         ]
    }
}
