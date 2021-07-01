//
//  CombineBufferTests.swift
//
//
//  Created by Max Obermeier on 27.01.21.
//

@testable import Apodini
@testable import ApodiniWebSocket
import OpenCombine
import XCTApodini


class CombineBufferTests: XCTestCase {
    static let blockTime: UInt32 = 10000
    
    var eventLoopGroup: EventLoopGroup?
    var threadPool: NIOThreadPool?
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 2)
        threadPool = NIOThreadPool(numberOfThreads: 2)
        threadPool?.start()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        try eventLoopGroup?.syncShutdownGracefully()
        try threadPool?.syncShutdownGracefully()
    }
    
    func testUninterruptedRun() throws {
        let eventLoop = try XCTUnwrap(self.eventLoopGroup?.next())
        let threadPool = try XCTUnwrap(self.threadPool)
        let done = eventLoop.makePromise(of: [Int].self)
        
        let sequence: [Int] = Array(1...100)
        
        let subject = PassthroughSubject<Int, Never>()
        
        let cancellable = subject
            .eagerBuffer(100)
            .syncMap { value -> EventLoopFuture<Int> in
                let promise = eventLoop.makePromise(of: Int.self)
                _ = threadPool.runIfActive(eventLoop: eventLoop) {
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
        let eventLoop = try XCTUnwrap(self.eventLoopGroup?.next())
        let threadPool = try XCTUnwrap(self.threadPool)
        
        let sequence: [Int] = Array(1...100)
        
        let subject = PassthroughSubject<Int, Never>()
        
        var latestValue: Int?
        
        let cancellable = subject
            .eagerBuffer(100)
            .syncMap { value -> EventLoopFuture<Int> in
                let promise = eventLoop.makePromise(of: Int.self)
                _ = threadPool.runIfActive(eventLoop: eventLoop) {
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
        let eventLoop = try XCTUnwrap(self.eventLoopGroup?.next())
        let threadPool = try XCTUnwrap(self.threadPool)
        let done = eventLoop.makePromise(of: [Int].self)
        
        let sequence: [Int] = Array(1...100)
        
        let subject = PassthroughSubject<Int, Never>()
        
        let cancellable = subject
            .eagerBuffer(100)
            .syncMap { value -> EventLoopFuture<Int> in
                let promise = eventLoop.makePromise(of: Int.self)
                _ = threadPool.runIfActive(eventLoop: eventLoop) {
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
