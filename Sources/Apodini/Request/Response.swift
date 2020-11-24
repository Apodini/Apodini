//
//  File.swift
//  
//
//  Created by Tim Gymnich on 24.11.20.
//

import Foundation
import NIO
@_implementationOnly import Vapor


protocol Response {
    init<T: Encodable>(body: T, encoder: EncoderProtocol) throws

    func payload<T: Decodable>(using decoder: DecoderProtocol) throws -> T?
}

extension Vapor.Response: Response {
  convenience init<T: Encodable>(body: T, encoder: EncoderProtocol) throws {
        let data = try encoder.encode(body)
        self.init(status: .ok, headers: HTTPHeaders(), body: Body(data: data))
    }

    func payload<T: Decodable>(using decoder: DecoderProtocol) throws -> T? {
        guard let data = self.body.data else { return nil }
        let result = try decoder.decode(T.self, from: data)
        return result
    }
}
