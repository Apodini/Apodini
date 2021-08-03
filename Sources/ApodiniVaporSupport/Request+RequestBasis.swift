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
import Vapor
import Foundation

extension Vapor.Request: RequestBasis {
    public var debugDescription: String {
        "Vapor.Request: \(self.description)"
    }

    public var information: InformationSet {
        InformationSet(headers.map { key, rawValue in
            AnyHTTPInformation(key: key, rawValue: rawValue)
        }).merge(with:
            [
                LoggingMetadataInformation(key: .init("VaporRequestDescription"), metadataValue: .string(self.description)),
                LoggingMetadataInformation(key: .init("HTTPBody"), metadataValue: .string(self.bodyData.count < 32_768 ? String(decoding: self.bodyData, as: UTF8.self) : "\(String(decoding: self.bodyData, as: UTF8.self).prefix(32_715))... (further bytes omitted since HTTP body too large!")),
                LoggingMetadataInformation(key: .init("HTTPContentType"), metadataValue: .string(self.content.contentType?.description ?? "unknown")),
                LoggingMetadataInformation(key: .init("hasSession"), metadataValue: .string(self.hasSession.description)),
                LoggingMetadataInformation(key: .init("route"), metadataValue: .string(self.route?.description ?? "unknown")),
                LoggingMetadataInformation(key: .init("HTTPVersion"), metadataValue: .string(self.version.description)),
                LoggingMetadataInformation(key: .init("url"), metadataValue: .string(self.url.description))
            ]
        )
    }
    
    /// Logging Metadata
    public var loggingMetadata: Logger.Metadata {
        [
            // Not interesting (no good data available): auth, client, password, parameters (we already have that), fileIO, storage,view,cache,query
            "VaporRequestDescription": .string(self.description),    // Includes Method, URL, HTTP version, headers and body
            "HTTPBody": .string(self.bodyData.count < 32_768 ? self.bodyData.base64EncodedString() : "\(self.bodyData.base64EncodedString().prefix(32_715))... (further bytes omitted since HTTP body too large!"),
            "HTTPContentType": .string(self.content.contentType?.description ?? ""),
            "hasSession": .string(self.hasSession.description),
            "HTTPMethod": .string(self.method.string),
            "route": .string(self.route?.description ?? ""),
            "HTTPVersion": .string(self.version.description),
            "url": .string(self.url.description)
        ]
    }
}
