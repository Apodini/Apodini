//
//  Request.swift
//  
//
//  Created by Paul Schmiedmayer on 7/12/20.
//
import Foundation
import NIO

protocol Request: CustomStringConvertible, CustomDebugStringConvertible {
    /// Returns a description of the Request.
    /// If the `ExporterRequest` also conforms to `CustomStringConvertible`, its `description`
    /// will be appended.
    var description: String { get }
    /// Returns a debug description of the Request.
    /// If the `ExporterRequest` also conforms to `CustomDebugStringConvertible`, its `debugDescription`
    /// will be appended.
    var debugDescription: String { get }

    var endpoint: AnyEndpoint { get }

    var eventLoop: EventLoop { get }

    func retrieveParameter<Element: Codable>(_ parameter: Parameter<Element>) throws -> Element
}
