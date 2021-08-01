//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import NIO
import Logging

/// A ``Request`` is a generalized wrapper around an ``InterfaceExporter``'s internal request type.
///
/// The information provided on the request is used by the Apodini framework to retrieve values for
/// ``Parameter``s. Furthermore, many of the request's properties are reflected on ``Connection``
/// where they are exposed to the user.
public protocol Request: CustomStringConvertible, CustomDebugStringConvertible {
    /// The `EventLoop` this request is to be handled on.
    var eventLoop: EventLoop { get }

    /// The remote address associated with this request.
    var remoteAddress: SocketAddress? { get }

    /// A set of arbitrary information that is associated with this request.
    var information: InformationSet { get }
    
    /// Metadata of the request (for Apodini Observe)
    var loggingMetadata: Logger.Metadata { get }

    /// A function for obtaining the value for a ``Parameter`` from this request.
    func retrieveParameter<Element: Codable>(_ parameter: Parameter<Element>) throws -> Element
}

extension Request {
    var loggingMetadata: Logger.Metadata {
        [:]
    }
}
