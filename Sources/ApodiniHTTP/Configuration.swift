//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Foundation
import Apodini
import ApodiniExtension
import ApodiniVaporSupport
import Vapor


extension HTTP {
    /// Configuration that can be used to customize the behavior of the ``HTTP`` exporter.
    public struct ExporterConfiguration {
        /// The `AnyEncoder` to be used for encoding responses
        public let encoder: AnyEncoder
        /// The `AnyDecoder` to be used for decoding requests
        public let decoder: AnyDecoder
        /// Indicates whether the HTTP route is interpreted case-sensitivly
        public let caseInsensitiveRouting: Bool
        
        
        /// Initializes the configuration of the ``HTTP`` exporter
        /// - Parameters:
        ///    - encoder: The to be used `AnyEncoder`, defaults to a `JSONEncoder`
        ///    - decoder: The to be used `AnyDecoder`, defaults to a `JSONDecoder`
        ///    - caseInsensitiveRouting: Indicates whether the HTTP route is interpreted case-sensitivly
        public init(encoder: AnyEncoder = HTTP.defaultEncoder,
                    decoder: AnyDecoder = HTTP.defaultDecoder,
                    caseInsensitiveRouting: Bool = false) {
            self.encoder = encoder
            self.decoder = decoder
            self.caseInsensitiveRouting = caseInsensitiveRouting
        }
    }
}
