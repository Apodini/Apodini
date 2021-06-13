import Apodini
@testable import ApodiniJobs
import XCTApodini

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
    
    class Observer: Apodini.ObservableObject {
        @Apodini.Published var num = 0
        var text = "Hello"
    }
    
    struct Keys: EnvironmentAccessible {
        var job: TestJob
    }
    
    func testJobInvocation() {
        let observer = Observer()
        let job = TestJob(observedObject: observer, num: 42, text: "Hello")
        // Only triggered by observer
        Schedule(job, on: "* * * * *", runs: 0, \Keys.job).configure(app)
        observer.num = 42
        // wait for first trigger to be completed
        usleep(10000)
        observer.text = "Bye"
    }
    
    func testJobObservableInvocationFromAnotherJob() throws {
        struct AnotherJob: Job {
            let observer: Observer
            
            // By changing observer it triggers the execution of other Jobs
            func run() {
                observer.num = 22
            }
        }
        
        struct Keys2: EnvironmentAccessible {
            var job: AnotherJob
        }
        
        let observer = Observer()
        let job1 = TestJob(observedObject: observer, num: 22, text: "Hello")
        let job2 = AnotherJob(observer: observer)
        Schedule(job1, on: "* * * * *", runs: 0, \Keys.job).configure(app)
        
        let eventLoop = EmbeddedEventLoop()
        // Schedule every full minute
        try app.scheduler.enqueue(job2, with: "* * * * *", \Keys2.job, on: eventLoop)
        
        let scheduled = try XCTUnwrap(app.scheduler.jobConfigurations[ObjectIdentifier(\Keys2.job)]?.scheduled)
        // Advance event loop to the next minute
        let second = Calendar.current.component(.second, from: Date())
        eventLoop.advanceTime(by: .seconds(Int64(60 - second)))
        
        XCTAssertScheduling(scheduled)
    }
    
    func testJobAsObservableObject() throws {
        struct EmittingJob: Job {
            @Apodini.Published var num = 0
            
            func run() {
                num = 42
            }
        }
        
        var wasRun = false
        
        struct SubscribingJob: Job {
            @Environment(\Keys2.emittingJob) var observedObject: EmittingJob
            
            let onRun: () -> Void
            
            func run() {
                onRun()
                XCTAssertTrue(_observedObject.changed)
                XCTAssertEqual(observedObject.num, 42)
            }
        }
        
        struct Keys2: EnvironmentAccessible {
            var emittingJob: EmittingJob
            var subscribingJob: SubscribingJob
        }
        
        let eventLoop = EmbeddedEventLoop()

        try app.scheduler.enqueue(EmittingJob(), with: "* * * * *", runs: 2, \Keys2.emittingJob, on: eventLoop)
        Schedule(
            SubscribingJob(onRun: {
                wasRun = true
            }),
            on: "* * * * *",
            runs: 0,
            \Keys2.subscribingJob)
            .configure(app)
        
        let scheduled = try XCTUnwrap(app.scheduler.jobConfigurations[ObjectIdentifier(\Keys2.emittingJob)]?.scheduled)
        // Advance event loop to the next minute
        let second = Calendar.current.component(.second, from: Date())
        eventLoop.advanceTime(by: .seconds(Int64(60 - second)))
        
        XCTAssertScheduling(scheduled)
        usleep(10000)
        XCTAssertTrue(wasRun)
    }
}
