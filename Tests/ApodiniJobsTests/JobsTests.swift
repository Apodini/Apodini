import Apodini
@testable import ApodiniJobs
import XCTApodini

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
    
    struct FailingJob2: Job {
        @Parameter var parameter: String
        
        /// Not used by tests
        func run() { }
    }
    
    class TestJob: Job {
        var num = 0
        
        func run() {
            num += 1
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
    
    struct KeyStore: EnvironmentAccessible {
        var failingJob: FailingJob
        var failingJob2: FailingJob2
        var testJob: TestJob
        var stateJob: StateJob
        var environmentJob: EnvironmentJob
    }
    
    func testFailingJobs() throws {
        XCTAssertThrowsError(try app.scheduler.dequeue(\KeyStore.failingJob))
        XCTAssertThrowsError(try app.scheduler.enqueue(FailingJob(), with: everyMinute, \KeyStore.failingJob, on: app.eventLoopGroup.next()))
        XCTAssertThrowsError(try app.scheduler.enqueue(FailingJob2(), with: everyMinute, \KeyStore.failingJob2, on: app.eventLoopGroup.next()))
        XCTAssertThrowsError(try app.scheduler.enqueue(TestJob(), with: "* * * *", \KeyStore.testJob, on: app.eventLoopGroup.next()))
        XCTAssertThrowsError(try app.scheduler.enqueue(TestJob(), with: "A B C D E", runs: 5, \KeyStore.testJob, on: app.eventLoopGroup.next()))
    }
    
    func testFatalError() throws {
        XCTAssertRuntimeFailure(Schedule(FailingJob(), on: self.everyMinute, \KeyStore.failingJob).configure(self.app),
                                "Request based property wrappers cannot be used with `Job`s")
        XCTAssertRuntimeFailure(Schedule(TestJob(), on: "A B C D E", \KeyStore.testJob).configure(self.app))
    }
    
    func testJobEnvironmentInjection() throws {
        try scheduler.enqueue(TestJob(), with: "*/10 * * * *", \KeyStore.testJob, on: app.eventLoopGroup.next())
        
        let job = try XCTUnwrap(app.storage[\KeyStore.testJob])
        
        XCTAssert(job.num == 0)
    }
    
    func testEnvironmentPropertyWrapper() throws {
        let eventLoop = EmbeddedEventLoop()
        
        try scheduler.enqueue(EnvironmentJob(), with: everyMinute, \KeyStore.environmentJob, on: eventLoop)
        
        let second = Calendar.current.component(.second, from: Date())
        eventLoop.advanceTime(by: .seconds(Int64(60 - second)))
        
        let job = try XCTUnwrap(app.storage[\KeyStore.environmentJob])
        
        XCTAssertTrue(job.contains)
    }
    
    func testEveryMinute() throws {
        let eventLoop = EmbeddedEventLoop()
        try app.scheduler.enqueue(TestJob(), with: everyMinute, \KeyStore.testJob, on: eventLoop)
        
        let scheduled = try XCTUnwrap(app.scheduler.jobConfigurations[ObjectIdentifier(\KeyStore.testJob)]?.scheduled)
        // Advance event loop to the next minute
        let second = Calendar.current.component(.second, from: Date())
        eventLoop.advanceTime(by: .seconds(Int64(60 - second)))
        
        XCTAssertScheduling(scheduled)
        
        let scheduled2 = try XCTUnwrap(app.scheduler.jobConfigurations[ObjectIdentifier(\KeyStore.testJob)]?.scheduled)
        eventLoop.advanceTime(by: .seconds(60))
        
        // Checking next scheduled value
        XCTAssertScheduling(scheduled2)
        
        let scheduled3 = try XCTUnwrap(app.scheduler.jobConfigurations[ObjectIdentifier(\KeyStore.testJob)]?.scheduled)
        
        // Remove from scheduler
        try app.scheduler.dequeue(\KeyStore.testJob)
        
        // Check if `Scheduled` was cancelled
        var error: Error?
        scheduled3.futureResult.whenFailure { error = $0 }
        XCTAssertNotNil(error)
    }
    
    func testEveryHour() throws {
        let eventLoop = EmbeddedEventLoop()
        try app.scheduler.enqueue(TestJob(), with: "* */1 * * *", \KeyStore.testJob, on: eventLoop)
        
        let scheduled = try XCTUnwrap(app.scheduler.jobConfigurations[ObjectIdentifier(\KeyStore.testJob)]?.scheduled)
        // Advance event loop to the next hour
        let minute = Calendar.current.component(.minute, from: Date())
        eventLoop.advanceTime(by: .minutes(Int64(60 - minute)))
        
        XCTAssertScheduling(scheduled)
        
        let scheduled2 = try XCTUnwrap(app.scheduler.jobConfigurations[ObjectIdentifier(\KeyStore.testJob)]?.scheduled)
        eventLoop.advanceTime(by: .hours(1))
        
        // Checking next scheduled value
        XCTAssertScheduling(scheduled2)
        
        let scheduled3 = try XCTUnwrap(app.scheduler.jobConfigurations[ObjectIdentifier(\KeyStore.testJob)]?.scheduled)
        
        // Remove from scheduler
        try app.scheduler.dequeue(\KeyStore.testJob)
        
        // Check if `Scheduled` was cancelled
        var error: Error?
        scheduled3.futureResult.whenFailure { error = $0 }
        XCTAssertNotNil(error)
    }
    
    func testStatePropertyWrapper() throws {
        let eventLoop = EmbeddedEventLoop()
        
        try app.scheduler.enqueue(StateJob(), with: everyMinute, \KeyStore.stateJob, on: eventLoop)
        
        let second = Calendar.current.component(.second, from: Date())
        eventLoop.advanceTime(by: .seconds(Int64(60 - second)))
        
        let job = try XCTUnwrap(app.storage[\KeyStore.stateJob])
        
        XCTAssertEqual(job.num, 1)
    }
    
    func testZeroRuns() throws {
        Schedule(TestJob(), on: everyMinute, runs: 0, \KeyStore.testJob).configure(app)
        let jobConfig = try XCTUnwrap(app.scheduler.jobConfigurations[ObjectIdentifier(\KeyStore.testJob)])
        XCTAssertNil(jobConfig.scheduled)
    }
    
    func testTwoRuns() throws {
        let eventLoop = EmbeddedEventLoop()
        try app.scheduler.enqueue(TestJob(), with: everyMinute, runs: 2, \KeyStore.testJob, on: eventLoop)
        
        let scheduled = try XCTUnwrap(app.scheduler.jobConfigurations[ObjectIdentifier(\KeyStore.testJob)]?.scheduled)
        // Advance event loop to the next minute
        let second = Calendar.current.component(.second, from: Date())
        eventLoop.advanceTime(by: .seconds(Int64(60 - second)))
        
        XCTAssertScheduling(scheduled)
        
        let scheduled2 = try XCTUnwrap(app.scheduler.jobConfigurations[ObjectIdentifier(\KeyStore.testJob)]?.scheduled)
        eventLoop.advanceTime(by: .seconds(60))
        
        // Check if `Scheduled` was cancelled
        var error: Error?
        scheduled2.futureResult.whenFailure { error = $0 }
        XCTAssertNotNil(error)
    }
}
