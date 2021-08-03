//
//  Request+LoggingMetadata.swift
//
//  Created by Philipp Zagar on 29.07.21.
//

import ApodiniExtension
import Vapor

extension Vapor.Request: LoggingMetadataAccessible {
    /// Logging Metadata
    public var loggingMetadata: Logger.Metadata {
        [
            // Not interesting (no good data available): auth, client, password, parameters (we already have that), fileIO, storage,view,cache,query
            "VaporRequestDescription":.string(self.description),    // Includes Method, URL, HTTP version, headers and body
            "HTTPBody":.string(self.bodyData.count < 32_768 ? self.bodyData.base64EncodedString() : "\(self.bodyData.base64EncodedString().prefix(32_715))... (further bytes omitted since HTTP body too large!"),
            "HTTPContentType":.string(self.content.contentType?.description ?? ""),
            "hasSession":.string(self.hasSession.description),
            "HTTPMethod":.string(self.method.string),
            "route":.string(self.route?.description ?? ""),
            "HTTPVersion":.string(self.version.description),
            "url":.string(self.url.description)
        ]
    }
}
