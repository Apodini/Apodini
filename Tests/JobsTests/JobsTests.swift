//
//  JobsTests.swift
//  
//
//  Created by Alexander Collins on 29.12.20.
//

import XCTApodini
import XCTest
import Apodini
@testable import Jobs

final class JobsTests: XCTApodiniTest {
    struct FailingJob: Job {
        @Parameter var userId: Int
        
        func run() { }
    }
    
    class TestJob: Job {
        var num = 0
        
        func run() {
            print("\(num)")
        }
    }
    
    struct KeyStore: KeyChain {
        var failingJob: FailingJob
        var testJob: TestJob
    }
    
    func testFailingJobs() throws {
        XCTAssertThrowsError(try Scheduler.shared.dequeue(\KeyStore.failingJob))
        XCTAssertThrowsError(try Scheduler.shared.enqueue(FailingJob(), with: "* * * * *", \KeyStore.failingJob, on: app.eventLoopGroup.next()))
        XCTAssertThrowsError(try Scheduler.shared.enqueue(TestJob(), with: "* * * *", \KeyStore.testJob, on: app.eventLoopGroup.next()))
        XCTAssertThrowsError(try Scheduler.shared.enqueue(TestJob(), with: "A B C D E", runs: 5, \KeyStore.testJob, on: app.eventLoopGroup.next()))
    }
    
    func testFatalError() throws {
        XCTAssertRuntimeFailure(Schedule(FailingJob(), on: "* * * * *", \KeyStore.failingJob).configure(self.app),
                                "Request based property wrappers cannot be used with `Job`s")
        XCTAssertRuntimeFailure(Schedule(TestJob(), on: "A B C D E", \KeyStore.testJob).configure(self.app))
    }
    
    func testEnvironmentInjection() throws {
        let scheduler = Environment(\.scheduler).wrappedValue
        let job = TestJob()
        try scheduler.enqueue(job, with: "*/10 * * * *", \KeyStore.testJob, on: app.eventLoopGroup.next())
        let environmentJob = Environment(\KeyStore.testJob).wrappedValue
        environmentJob.num = 42
        XCTAssert(environmentJob.num == job.num)
    }
    
    func testEveryMinute() throws {
        Schedule(TestJob(), on: "* * * * *", \KeyStore.testJob).configure(app)
        let jobConfig = try XCTUnwrap(Scheduler.shared.jobConfigurations[ObjectIdentifier(\KeyStore.testJob)])
        XCTAssertNotNil(jobConfig.scheduled)
        
        try Scheduler.shared.dequeue(\KeyStore.testJob)
    }
    
    func testZeroRuns() throws {
        Schedule(TestJob(), on: "* * * * *", runs: 0, \KeyStore.testJob).configure(app)
        let jobConfig = try XCTUnwrap(Scheduler.shared.jobConfigurations[ObjectIdentifier(\KeyStore.testJob)])
        XCTAssertNil(jobConfig.scheduled)
        
        try Scheduler.shared.dequeue(\KeyStore.testJob)
    }
}
