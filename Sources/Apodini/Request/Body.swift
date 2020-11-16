//
//  Body.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIOFoundationCompat
import Vapor
import Foundation

/// Any type which can decode `Data` into a `Decodable` type.
public protocol DataDecoder {
    /// Decode `Data` into the provided type.
    ///
    /// - Parameters:
    ///   - type:  The `Type` to be decoded.
    ///   - data:  The `Data` to be decoded.
    ///
    /// - Returns: The decoded value of type `D`.
    /// - Throws:  Any error that occurs during decode.
    func decode<D: Decodable>(_ type: D.Type, from data: Data) throws -> D
}

extension JSONDecoder: DataDecoder {}
extension PropertyListDecoder: DataDecoder {}

@propertyWrapper
public class Body<Element: Codable>: RequestInjectable {
    private var element: Element?
    private var decoder: DataDecoder
    
    
    public var wrappedValue: Element {
        guard let element = element else {
            fatalError("You can only access the body while you handle a request")
        }
        
        return element
    }

    public init(decoder: DataDecoder = JSONDecoder()) {
        self.decoder = decoder
    }
    
    
    func inject(using request: Vapor.Request) throws {
        guard let byteBuffer = request.body.data, let data = byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes) else {
            throw Vapor.Abort(.internalServerError, reason: "Could not read the HTTP request's body")
        }
        
        element = try decoder.decode(Element.self, from: data)
    }
    
    func disconnect() {
        self.element = nil
    }
}
