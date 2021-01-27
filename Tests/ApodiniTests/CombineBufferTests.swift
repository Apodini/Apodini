//
//  CombineBufferTests.swift
//
//
//  Created by Max Obermeier on 27.01.21.
//

import XCTest
import NIO
import WebSocketInfrastructure
import OpenCombine
@testable import Apodini

class CombineBufferTests: ApodiniTests {
    static let blockTime: UInt32 = 10000
    
    func testUninterruptedRun() throws {
        let eventLoop = app.eventLoopGroup.next()
        let done = eventLoop.makePromise(of: [Int].self)
        
        let sequence: [Int] = Array(1...100)
        
        let subject = PassthroughSubject<Int, Never>()
        
        let cancellable = subject.buffer().syncMap { value -> EventLoopFuture<Int> in
            let promise = eventLoop.makePromise(of: Int.self)
            _ = self.app.threadPool.runIfActive(eventLoop: eventLoop) {
                usleep(CombineBufferTests.blockTime)
                promise.succeed(value)
            }
            return promise.futureResult
        }
        .collect()
        .sink(receiveValue: { value in
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
        
        sequence.forEach { value in
            subject.send(value)
        }
        subject.send(completion: .finished)
        
        XCTAssertEqual(sequence, try done.futureResult.wait())
        // ignore 'unused c' warning while keeping the publisher in memory
        _ = cancellable
    }
    
    func testCancelledRun() throws {
        let eventLoop = app.eventLoopGroup.next()
        
        let sequence: [Int] = Array(1...100)
        
        let subject = PassthroughSubject<Int, Never>()
        
        var latestValue: Int?
        
        let cancellable = subject.buffer().syncMap { value -> EventLoopFuture<Int> in
            let promise = eventLoop.makePromise(of: Int.self)
            _ = self.app.threadPool.runIfActive(eventLoop: eventLoop) {
                usleep(CombineBufferTests.blockTime)
                latestValue = value
                promise.succeed(value)
            }
            return promise.futureResult
        }
        .collect()
        .sink(receiveValue: { _ in })
        
        sequence.forEach { value in
            subject.send(value)
        }
        subject.send(completion: .finished)
        
        usleep(50 * CombineSyncMapTests.blockTime)
        cancellable.cancel()
        usleep(50 * CombineSyncMapTests.blockTime)
        
        XCTAssertLessThanOrEqual(latestValue ?? 100, 50)
    }
    
    private enum RandomError: String, Error {
        case fiftyWasUsed
    }
    
    func testEarlyCompletedRun() throws {
        let eventLoop = app.eventLoopGroup.next()
        let done = eventLoop.makePromise(of: [Int].self)
        
        let sequence: [Int] = Array(1...100)
        
        let subject = PassthroughSubject<Int, Never>()
        
        let cancellable = subject.buffer().syncMap { value -> EventLoopFuture<Int> in
            let promise = eventLoop.makePromise(of: Int.self)
            _ = self.app.threadPool.runIfActive(eventLoop: eventLoop) {
                usleep(CombineBufferTests.blockTime)
                promise.succeed(value)
            }
            return promise.futureResult
        }
        .collect()
        .sink(receiveValue: { value in
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
        
        sequence[...50].forEach { value in
            subject.send(value)
        }
        subject.send(completion: .finished)
        sequence[51...].forEach { value in
            subject.send(value)
        }
        
        XCTAssertEqual(Array(sequence[...50]), try done.futureResult.wait())
        // ignore 'unused c' warning while keeping the publisher in memory
        _ = cancellable
    }
}
