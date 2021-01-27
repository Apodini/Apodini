//
//  JobsTests.swift
//  
//
//  Created by Alexander Collins on 29.12.20.
//

import XCTApodini
import XCTest
import Apodini
import NIO
@testable import Jobs

final class JobsTests: XCTApodiniTest {
    let everyMinute = "* * * * *"
    
    var scheduler: Scheduler {
        app.scheduler
    }
    
    struct FailingJob: Job {
        @Environment(\.connection) var connection: Connection
        
        /// Not used by tests
        func run() { }
    }
    
    class TestJob: Job {
        var num = 0
        
        func run() {
            print("\(num)")
        }
    }
    
    struct StateJob: Job {
        @State var num = 0
        
        func run() {
            num += 1
        }
    }
    
    struct EnvironmentJob: Job {
        @Environment(\.storage) var storage: Storage
        @State var contains = false
        
        func run() {
            contains = storage.contains(\KeyStore.environmentJob)
        }
    }
    
    struct KeyStore: KeyChain {
        var failingJob: FailingJob
        var testJob: TestJob
        var stateJob: StateJob
        var environmentJob: EnvironmentJob
    }
    
    func testFailingJobs() throws {
        XCTAssertThrowsError(try scheduler.dequeue(\KeyStore.failingJob))
        XCTAssertThrowsError(try scheduler.enqueue(FailingJob(), with: everyMinute, \KeyStore.failingJob, on: app.eventLoopGroup.next()))
        XCTAssertThrowsError(try scheduler.enqueue(TestJob(), with: "* * * *", \KeyStore.testJob, on: app.eventLoopGroup.next()))
        XCTAssertThrowsError(try scheduler.enqueue(TestJob(), with: "A B C D E", runs: 5, \KeyStore.testJob, on: app.eventLoopGroup.next()))
    }
    
    func testFatalError() throws {
        XCTAssertRuntimeFailure(Schedule(FailingJob(), on: self.everyMinute, \KeyStore.failingJob).configure(self.app),
                                "Request based property wrappers cannot be used with `Job`s")
        XCTAssertRuntimeFailure(Schedule(TestJob(), on: "A B C D E", \KeyStore.testJob).configure(self.app))
    }
    
    func testJobEnvironmentInjection() throws {
        try scheduler.enqueue(TestJob(), with: "*/10 * * * *", \KeyStore.testJob, on: app.eventLoopGroup.next())
        
        let job = environmentJob(\KeyStore.testJob, app: app)
        
        XCTAssert(job.num == 0)
    }
    
    func testStatePropertyWrapper() throws {
        let eventLoop = EmbeddedEventLoop()
        
        try scheduler.enqueue(StateJob(), with: everyMinute, \KeyStore.stateJob, on: eventLoop)
        
        let second = Calendar.current.component(.second, from: Date())
        eventLoop.advanceTime(by: .seconds(Int64(60 - second)))
        
        let job = environmentJob(\KeyStore.stateJob, app: app)

        XCTAssertEqual(job.num, 1)
    }
    
    func testEnvironmentPropertyWrapper() throws {
        let eventLoop = EmbeddedEventLoop()
        
        try scheduler.enqueue(EnvironmentJob(), with: everyMinute, \KeyStore.environmentJob, on: eventLoop)
        
        let second = Calendar.current.component(.second, from: Date())
        eventLoop.advanceTime(by: .seconds(Int64(60 - second)))
        
        let job = environmentJob(\KeyStore.environmentJob, app: app)
        
        XCTAssertTrue(job.contains)
    }
    
    func testEveryMinute() throws {
        Schedule(TestJob(), on: everyMinute, \KeyStore.testJob).configure(app)
        let jobConfig = try XCTUnwrap(scheduler.jobConfigurations[ObjectIdentifier(\KeyStore.testJob)])
        XCTAssertNotNil(jobConfig.scheduled)
        
        try scheduler.dequeue(\KeyStore.testJob)
    }
    
    func testZeroRuns() throws {
        Schedule(TestJob(), on: everyMinute, runs: 0, \KeyStore.testJob).configure(app)
        let jobConfig = try XCTUnwrap(scheduler.jobConfigurations[ObjectIdentifier(\KeyStore.testJob)])
        XCTAssertNil(jobConfig.scheduled)
        
        try scheduler.dequeue(\KeyStore.testJob)
    }
}
