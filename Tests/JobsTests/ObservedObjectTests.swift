import XCTApodini
import XCTest
import Apodini
import NIO
@testable import Jobs

final class ObservedObjectTests: XCTApodiniTest {
    struct TestJob: Job {
        @ObservedObject var observedObject: Observer
        var num: Int
        var text: String
        
        func run() {
            // Job is only executed by the observed object
            XCTAssertTrue(_observedObject.changed)
            XCTAssertEqual(observedObject.num, num)
            XCTAssertEqual(observedObject.text, text)
        }
    }
    
    struct Observer: Apodini.ObservableObject {
        @Apodini.Published var num = 0
        @Apodini.Published var text = "Hello"
    }
    
    struct Keys: KeyChain {
        var job: TestJob
    }
    
    func testJobInvocation() {
        let observer = Observer()
        let job = TestJob(observedObject: observer, num: 42, text: "Hello")
        // Only triggered by observer
        Schedule(job, on: "* * * * *", runs: 0, \Keys.job).configure(app)
        observer.num = 42
        observer.text = "Hello"
    }
    
    func testJobObservableInvocationFromAnotherJob() throws {
        struct AnotherJob: Job {
            let observer: Observer
            
            // By changing observer it triggers the execution of other Jobs
            func run() {
                observer.num = 22
            }
        }
        
        struct Keys2: KeyChain {
            var job: AnotherJob
        }
        
        let observer = Observer()
        let job1 = TestJob(observedObject: observer, num: 22, text: "Hello")
        let job2 = AnotherJob(observer: observer)
        Schedule(job1, on: "* * * * *", runs: 0, \Keys.job).configure(app)
        
        let eventLoop = EmbeddedEventLoop()
        // Schedule every full minute
        try Scheduler.shared.enqueue(job2, with: "* * * * *", runs: 1, \Keys2.job, on: eventLoop)
        // Advancing event loop 70 seconds
        // Job should have been fired by now
        eventLoop.advanceTime(by: .seconds(70))
        
        let scheduled = try XCTUnwrap(Scheduler.shared.jobConfigurations[ObjectIdentifier(\Keys2.job)]?.scheduled)
        
        XCTAssertScheduling(scheduled)
    }
    
    func testJobAsObservableObject() throws {
        struct EmittingJob: Job {
            @Apodini.Published var num = 0
            
            func run() {
                num = 42
            }
        }
        
        struct SubscribingJob: Job {
            @ObservedObject(\Keys2.emittingJob) var observedObject: EmittingJob
            
            func run() {
                XCTAssertTrue(_observedObject.changed)
                XCTAssertEqual(observedObject.num, 42)
            }
        }
        
        struct Keys2: KeyChain {
            var emittingJob: EmittingJob
            var subscribingJob: SubscribingJob
        }
        
        let eventLoop = EmbeddedEventLoop()
        try Scheduler.shared.enqueue(EmittingJob(), with: "* * * * *", runs: 1, \Keys2.emittingJob, on: eventLoop)
        Schedule(SubscribingJob(), on: "* * * * *", runs: 0, \Keys2.subscribingJob).configure(app)
        eventLoop.advanceTime(by: .seconds(70))
        
        let scheduled = try XCTUnwrap(Scheduler.shared.jobConfigurations[ObjectIdentifier(\Keys2.emittingJob)]?.scheduled)
        
        XCTAssertScheduling(scheduled)
    }
}
