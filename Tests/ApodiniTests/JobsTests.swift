// swiftlint:disable force_unwrapping force_cast
//
//  File.swift
//  
//
//  Created by Alexander Collins on 29.12.20.
//

@testable import Apodini
import XCTest

final class JobsTests: ApodiniTests {
    struct FailingJob: Job {
        @_Request var request: Request
        
        func run() { }
    }
    
    class TestJob: Job {
        var num = 0
        
        func run() {
            print("\(num)")
        }
    }
    
    struct KeyStore: ApodiniKeys {
        var failingJob: FailingJob
        var testJob: TestJob
    }
    
    func testFailingJobs() throws {
        XCTAssertThrowsError(try Scheduler.shared.dequeue(\KeyStore.failingJob))
        XCTAssertThrowsError(try Scheduler.shared.enqueue(FailingJob(), with: "* * * * *", \KeyStore.failingJob, on: app.eventLoopGroup.next()))
        XCTAssertThrowsError(try Scheduler.shared.enqueue(TestJob(), with: "* * * *", \KeyStore.testJob, on: app.eventLoopGroup.next()))
        XCTAssertThrowsError(try Scheduler.shared.enqueue(TestJob(), with: "A B C D E", runs: 5, \KeyStore.testJob, on: app.eventLoopGroup.next()))
    }
    
    func testEnvironmentInjection() throws {
        let scheduler = EnvironmentValues.shared.scheduler
        let job = TestJob()
        try scheduler.enqueue(job, with: "*/10 * * * *", \KeyStore.testJob, on: app.eventLoopGroup.next())
        let environmentJob = EnvironmentValues.shared.values[ObjectIdentifier(\KeyStore.testJob)] as! TestJob
        environmentJob.num = 42
        XCTAssert(environmentJob.num == job.num)
    }
    
    func testScheduling() throws {
        Schedule(TestJob(), on: "* * * * *", \KeyStore.testJob).configure(app)
        let jobConfig = Scheduler.shared.jobConfigurations[ObjectIdentifier(\KeyStore.testJob)]!
        XCTAssertNotNil(jobConfig.scheduled)
    }
}
// swiftlint:enable force_unwrapping force_cast
