//
//  Codable.swift
//  
//
//  Created by Tim Gymnich on 22.12.20.
//

import Foundation
import NIO


extension EventLoopFuture: Encodable where Value: Encodable {
    public func encode(to encoder: Encoder) throws {
        let encodable = try self.wait()
        try encodable.encode(to: encoder)
    }
}

protocol EncoderProtocol {
    func encode<T: Encodable>(_ value: T) throws -> Data
}

extension JSONEncoder: EncoderProtocol {}


extension Encodable {
    func encode(using encoder: EncoderProtocol, on eventLoop: EventLoop) -> EventLoopFuture<Data> {
        eventLoop.flatSubmit {
            do {
                let data = try encoder.encode(self)
                return eventLoop.makeSucceededFuture(data)
            } catch {
                return eventLoop.makeFailedFuture(error)
            }
        }
    }
}
