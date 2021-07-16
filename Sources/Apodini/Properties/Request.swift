//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import NIO

/// A ``Request`` is a generalized wrapper around an ``InterfaceExporter``'s internal request type.
///
/// The information provided on the request is used by the Apodini framework to retrieve values for
/// ``Parameter``s. Furthermore, many of the request's properties are reflected on ``Connection``
/// where they are exposed to the user.
public protocol Request: CustomStringConvertible, CustomDebugStringConvertible {
    /// Returns a description of the Request.
    /// If the `ExporterRequest` also conforms to `CustomStringConvertible`, its `description`
    /// will be appended.
    var description: String { get }
    /// Returns a debug description of the Request.
    /// If the `ExporterRequest` also conforms to `CustomDebugStringConvertible`, its `debugDescription`
    /// will be appended.
    var debugDescription: String { get }

    /// The `EventLoop` this request is to be handled on.
    var eventLoop: EventLoop { get }

    /// The remote address associated with this request.
    var remoteAddress: SocketAddress? { get }
    
    /// A set of arbitrary information that is associated with this request.
    var information: Set<AnyInformation> { get }

    /// A function for obtaining the value for a ``Parameter`` from this request.
    func retrieveParameter<Element: Codable>(_ parameter: Parameter<Element>) throws -> Element
}
