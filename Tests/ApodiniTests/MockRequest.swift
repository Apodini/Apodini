//
//  MockRequest.swift
//  
//
//  Created by Tim Gymnich on 19.12.20.
//

import Foundation
import Apodini
import NIO
import Fluent

struct MockRequest: Request {
    private var parameterDecoder: (UUID) -> Codable?
    private var eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    var eventLoop: EventLoop { eventLoopGroup.next() }
    var database: Fluent.Database?
    var description: String = "Mock Request"

    init(database: Fluent.Database? = nil, parameterDecoder: @escaping (UUID) -> Codable? = { _ in nil }) {
        self.database = database
        self.parameterDecoder = parameterDecoder
    }

    func parameter<T: Codable>(for parameter: UUID) throws -> T? {
        parameterDecoder(parameter) as? T
    }
}
