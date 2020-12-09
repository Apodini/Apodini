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
    init<T: Encodable>(encoding: T) throws
}

typealias VaporResponse = Vapor.Response

extension VaporResponse: Response {
    convenience init<T: Encodable>(encoding body: T) throws {
        let data = try JSONEncoder().encode(body)
        self.init(body: Body(data: data))
    }
}
