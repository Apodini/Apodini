//
//  Request.swift
//  
//
//  Created by Paul Schmiedmayer on 7/12/20.
//
import Foundation
import NIO

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

    /// A function for obtaining the value for a ``Parameter`` from this request.
    func retrieveParameter<Element: Codable>(_ parameter: Parameter<Element>) throws -> Element
}
