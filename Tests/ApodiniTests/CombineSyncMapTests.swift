//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTest
import OpenCombine
@testable import Apodini
@testable import ApodiniWebSocket

class CombineSyncMapTests: ApodiniTests {
    static let blockTime: UInt32 = 10000
    
    func testUninterruptedRun() throws {
        let eventLoop = app.eventLoopGroup.next()
        var commonResource: Int = 0
        let done = eventLoop.makePromise(of: [Int].self)
        
        let sequence: [Int] = Array(1...100)
        
        let cancellable = Publishers.Sequence<[Int], Never>(sequence: sequence)
        .syncMap { number -> EventLoopFuture<Int> in
            let promise = eventLoop.makePromise(of: Int.self)
            commonResource = number
            _ = self.app.threadPool.runIfActive(eventLoop: eventLoop) {
                usleep(CombineSyncMapTests.blockTime)
                promise.succeed(commonResource)
            }
            return promise.futureResult
        }
        .collect()
        .sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                break
            }
        }, receiveValue: { value in
            done.succeed(value.map { result in
                switch result {
                case .success(let value):
                    return value
                case .failure(let error):
                    done.fail(error)
                    return 0
                }
            })
        })
        
        XCTAssertEqual(sequence, try done.futureResult.wait())
        // ignore 'unused c' warning while keeping the publisher in memory
        _ = cancellable
    }
    
    func testCancelledRun() throws {
        let eventLoop = app.eventLoopGroup.next()
        var commonResource: Int = 0
        
        let sequence: [Int] = Array(1...100)
        
        let cancellable = Publishers.Sequence<[Int], Error>(sequence: sequence)
        .syncMap { number -> EventLoopFuture<Int> in
            let promise = eventLoop.makePromise(of: Int.self)
            commonResource = number
            _ = self.app.threadPool.runIfActive(eventLoop: eventLoop) {
                usleep(CombineSyncMapTests.blockTime)
                promise.succeed(commonResource)
            }
            return promise.futureResult
        }
        .collect()
        .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        
        
        usleep(50 * CombineSyncMapTests.blockTime)
        cancellable.cancel()
        usleep(50 * CombineSyncMapTests.blockTime)
        
        XCTAssertLessThanOrEqual(commonResource, 50)
    }
    
    private enum RandomError: String, Error {
        case fiftyWasUsed
    }
    
    func testFailingRun() throws {
        let eventLoop = app.eventLoopGroup.next()
        var commonResource: Int = 0
        let done = eventLoop.makePromise(of: [Int].self)
        
        let sequence: [Int] = Array(1...100)
        
        let cancellable = Publishers.Sequence<[Int], Error>(sequence: sequence)
        .syncMap { number -> EventLoopFuture<Int> in
            let promise = eventLoop.makePromise(of: Int.self)
            commonResource = number
            _ = self.app.threadPool.runIfActive(eventLoop: eventLoop) {
                usleep(CombineSyncMapTests.blockTime)

                if number == 50 {
                    promise.fail(RandomError.fiftyWasUsed)
                } else {
                    promise.succeed(commonResource)
                }
            }
            return promise.futureResult
        }
        .collect()
        .sink(receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                done.fail(error)
            case .finished:
                break
            }
        }, receiveValue: { value in
            done.succeed(value.map { result in
                switch result {
                case .success(let value):
                    return value
                case .failure(let error):
                    done.fail(error)
                    return 0
                }
            })
        })
        
        XCTAssertThrowsError(try done.futureResult.wait())
        // ignore 'unused c' warning while keeping the publisher in memory
        _ = cancellable
    }
}
