@testable import Apodini
@testable import ApodiniREST
import Vapor
import Foundation
import XCTApodini


class ObservedObjectTests: XCTApodiniDatabaseBirdTest {
    // check setting changed
    class TestObservable: Apodini.ObservableObject {
        @Apodini.Published var number: Int
        @Apodini.Published var text: String
        
        init(_ number: Int = 0, _ text: String = "Hello") {
            self.number = number
            self.text = text
        }
    }
    
    struct Keys: EnvironmentAccessible {
        var testObservable: TestObservable
    }
    
    struct TestHandler: Handler {
        @Apodini.EnvironmentObject(\Keys.testObservable) var testObservable: TestObservable
        
        func handle() -> String {
            testObservable.text
        }
    }
    
    func testHandlerObservedObjectCollection() {
        struct TestHandler: Handler {
            @ObservedObject var testObservable = TestObservable()
            
            func handle() -> String {
                "Hello World"
            }
        }
        
        let handler = TestHandler()
        let observedObjects = collectObservedObjects(from: handler)
        
        XCTAssertEqual(observedObjects.count, 1)
        XCTAssert(observedObjects[0] is ObservedObject<TestObservable>)
    }
    
    func testObservedObjectEnvironmentInjection() throws {
        struct TestHandler: Handler {
            @Apodini.EnvironmentObject(\Keys.testObservable) var testObservable: TestObservable
            
            func handle() -> String {
                testObservable.text
            }
        }
        
        // Test missing environment value
        XCTAssertRuntimeFailure(TestHandler().handle())
        
        // Test correct injection
        let testObservable = TestObservable()
        app.storage.set(\Keys.testObservable, to: testObservable)
        
        var handler = TestHandler()
        activate(&handler)
        handler = handler.inject(app: app)
        
        let observedObjects = collectObservedObjects(from: handler)
        
        XCTAssertNoThrow(handler.handle())
        XCTAssertEqual(observedObjects.count, 1)
        let observedObject = try XCTUnwrap(observedObjects[0] as? Apodini.Environment<Keys, TestObservable>)
        XCTAssert(observedObject.wrappedValue === testObservable)
    }
    
    func testRegisterObservedListener() throws {
        struct TestHandler: Handler {
            @Apodini.Environment(\Keys.testObservable) var testObservable: TestObservable
            
            func handle() -> String {
                testObservable.text
            }
        }
        
        struct TestListener: ObservedListener {
            var eventLoop: EventLoop
            
            var context: ConnectionContext<Vapor.Request, TestHandler>

            func onObservedDidChange(_ observedObject: AnyObservedObject,
                                     _ event: TriggerEvent) {
                do {
                    try XCTCheckResponse(
                        context.handle(eventLoop: eventLoop, observedObject: observedObject, event: event),
                        content: "Hello Swift"
                    )
                } catch {
                    XCTFail(error.localizedDescription)
                }
            }
        }
        
        let expectation = XCTestExpectation(description: "Observation is executed")
        expectation.assertForOverFulfill = true
        
        try XCTCheckHandler(TestHandler()) {
            MockRequest(expectation: "Hello")
            MockObservedListener(.response("Hello Swift"), timeoutExpectation: expectation)
            ExecuteClosure<String> {
                testObservable.text = "Hello Swift"
            }
        }
    }
    
    func testObservedListenerNotShared() {
        struct TestHandler: Handler {
            @Apodini.Environment(\Keys.testObservable) var testObservable: TestObservable
            
            func handle() -> String {
                testObservable.text
            }
        }
        
        class MandatoryTestListener: ObservedListener {
            var eventLoop: EventLoop
            
            var context: ConnectionContext<Vapor.Request, TestHandler>
            
            var wasCalled = false
            
            let number: Int
            
            init(eventLoop: EventLoop, number: Int, context: ConnectionContext<Vapor.Request, TestHandler>) {
                self.eventLoop = eventLoop
                self.context = context
                self.number = number
            }
            
            func onObservedDidChange(_ observedObject: AnyObservedObject,
                                     _ event: TriggerEvent) {
                wasCalled = true
            }
            
            deinit {
                XCTAssertTrue(wasCalled, "Number \(number) failed!")
            }
        }
        
        
        let firstExpectation = XCTestExpectation(description: "Observation is executed")
        firstExpectation.assertForOverFulfill = true
        let secondExpectation = XCTestExpectation(description: "Observation is executed")
        secondExpectation.assertForOverFulfill = true
        
        try XCTCheckHandler(TestHandler()) {
            MockRequest(expectation: "Hello")
            MockObservedListener(.response("Hello Swift"), timeoutExpectation: firstExpectation)
        }
        
        try XCTCheckHandler(TestHandler()) {
            MockRequest(expectation: "Hello")
            MockObservedListener(.response("Hello Swift"), timeoutExpectation: secondExpectation)
        }
        
        wait(for: [firstExpectation, secondExpectation], timeout: 0)
    }
    
    func testObservedListenerNotShared() throws {
        let testObservable = TestObservable()
        app.storage.set(\Keys.testObservable, to: testObservable)
        
        let firstExpectation = XCTestExpectation(description: "Observation is executed")
        firstExpectation.assertForOverFulfill = true
        let secondExpectation = XCTestExpectation(description: "Observation is executed")
        secondExpectation.assertForOverFulfill = true
        
        try XCTCheckHandler(TestHandler()) {
            MockRequest(expectation: "Hello")
            MockObservedListener(.response("Hello Swift"), timeoutExpectation: firstExpectation)
        }
        
        try XCTCheckHandler(TestHandler()) {
            MockRequest(expectation: "Hello")
            MockObservedListener(.response("Hello Swift"), timeoutExpectation: secondExpectation)
        }
        
        testObservable.text = "Hello Swift"
        wait(for: [firstExpectation, secondExpectation], timeout: 0)
    }
    
    func testChangedProperty() throws {
        struct TestHandler: Handler {
            @Apodini.Environment(\Keys.testObservable) var observable: TestObservable
            
            func handle() -> Bool {
                _observable.changed
            }
        }
        
        struct TestListener: ObservedListener {
            var eventLoop: EventLoop
            
            var context: ConnectionContext<Vapor.Request, TestHandler>
            
            func onObservedDidChange(_ observedObject: AnyObservedObject,
                                     _ event: TriggerEvent) {
                do {
                    try XCTCheckResponse(
                        context.handle(eventLoop: eventLoop, observedObject: observedObject, event: event),
                        content: "Hello Swift"
                    )
                } catch {
                    XCTFail(error.localizedDescription)
                }
            }
        }
        app.storage.set(\Keys.testObservable, to: testObservable)
        
        let expectation = XCTestExpectation(description: "Observation is executed")
        expectation.assertForOverFulfill = true
        
        try XCTCheckHandler(TestHandler()) {
            MockRequest(expectation: false)
            MockObservedListener(.response(true), timeoutExpectation: expectation)
            ExecuteClosure<Bool> {
                testObservable.text = "Hello Swift"
            }
            MockRequest(expectation: false)
        }
        
        wait(for: [expectation], timeout: 0)
    }
    
    func testDeferredDefualtValueInitialization() throws {
        class InitializationObserver: Apodini.ObservableObject {
            static var updateLatestCreatedInitializationObserver: () -> () = {}
            
            @Apodini.Published var id: Int
            
            
            init(_ id: Int = 42) {
                self.id = id
                
                InitializationObserver.updateLatestCreatedInitializationObserver = {
                    self.id = -1
                }
            }
        }
        
        struct Keys: EnvironmentAccessible {
            var initializationObserver: InitializationObserver
        }
        
        struct TestHandler: Handler {
            @ObservedObject var observable = InitializationObserver()
            
            
            func handle() -> Int {
                observable.id
            }
        }
        
        let initializationObserver = InitializationObserver(0)
        app.storage.set(\Keys.initializationObserver, to: initializationObserver)
        
        let notExecuteExpectation = XCTestExpectation(description: "Observation not executed")
        notExecuteExpectation.isInverted = true
        
        try XCTCheckHandler(TestHandler()) {
            MockRequest(expectation: 42)
            MockObservedListener(.response(42), timeoutExpectation: notExecuteExpectation)
            ExecuteClosure<Int> {
                initializationObserver.id = 1
            }
            MockRequest(expectation: 42)
        }
        
        wait(for: [notExecuteExpectation], timeout: 0)
        
        
        let expectation = XCTestExpectation(description: "Observation executed")
        expectation.expectedFulfillmentCount = 1
        
        try XCTCheckHandler(TestHandler()) {
            MockRequest(expectation: 42)
            MockObservedListener(.response(-1), timeoutExpectation: expectation)
            ExecuteClosure<Int> {
                InitializationObserver.updateLatestCreatedInitializationObserver()
            }
            MockRequest(expectation: -1)
        }
        
        wait(for: [expectation], timeout: 0)
    }
    
    
    class TestListener<H: Handler>: ObservedListener {
        var eventLoop: EventLoop
        
        var context: ConnectionContext<String, H>
        
        var result: (() -> EventLoopFuture<String>)?
        
        init(eventLoop: EventLoop, context: ConnectionContext<String, H>) {
            self.eventLoop = eventLoop
            self.context = context
        }

        func onObservedDidChange(_ observedObject: AnyObservedObject, _ event: TriggerEvent) {
            result = {
                self.context.handle(eventLoop: self.eventLoop, observedObject: observedObject, event: event).map { response in
                    if response.content == nil {
                        return "Nothing"
                    }
                   
                   return "\(response.content!)"
                }
            }
        }
    }
    
    func testObservationAfterUsingSetter() throws {
        struct TestHandler: Handler {
            @ObservedObject var testObservable = TestObservable()
            
            @Apodini.Environment(\.connection) var connection
            
            @State var count: Int = 1
            
            let secondObservable: TestObservable
            
            func handle() -> Apodini.Response<String> {
                defer {
                    count += 1
                    if testObservable.text == "World" {
                        // should not trigger evaluation
                        testObservable.text = "Cancelled"
                        testObservable = secondObservable
                    }
                }
                let response = "\(count): \(testObservable.number) - \(testObservable.text) (\(_testObservable.changed ? "event" : "request"))"
                switch connection.state {
                case .open:
                    return .send(response)
                case .end:
                    return .final(response)
                }
            }
        }
        
        
        let eventLoop = app.eventLoopGroup.next()
        
        let exporter = MockExporter<String>()
        
        let observable = TestObservable()
        let observable2 = TestObservable(100, "Hello, World!")
        var testHandler = TestHandler(testObservable: observable, secondObservable: observable2).inject(app: app)
        activate(&testHandler)
        let endpoint = testHandler.mockEndpoint(app: app)
        
        let context = endpoint.createConnectionContext(for: exporter)
        
        let listener = TestListener(eventLoop: eventLoop, context: context)
        

        context.register(listener: listener)

        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: eventLoop, final: false),
            content: "1: 0 - Hello (request)",
            connectionEffect: .open
        )
        
        // should trigger second evaluation
        observable.number = 1
        
        XCTAssertNotNil(listener.result)
        XCTAssertEqual(try listener.result!().wait(), "2: 1 - Hello (event)")
        listener.result = nil
        
        // should trigger third evaluation, which triggers another evaluation, but also changes observable object
        observable.text = "World"
        XCTAssertNotNil(listener.result)
        XCTAssertEqual(try listener.result!().wait(), "3: 1 - World (event)")
        // test that the event triggered by the third evaluation was cancelled (this should happen, as at the time it would be
        // evaluated, the @ObservedObject by which the event was observed observes a different observable)
        XCTAssertNotNil(listener.result)
        XCTAssertEqual(try listener.result!().wait(), "Nothing")
        
        listener.result = nil
        
        // should not trigger
        observable.text = "Never"
        XCTAssertNil(listener.result)
        
        // should trigger forth evaluation
        observable2.number = 101
        XCTAssertNotNil(listener.result)
        XCTAssertEqual(try listener.result!().wait(), "4: 101 - Hello, World! (event)")
        listener.result = nil
        
        // final evaluation
        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: eventLoop),
            content: "5: 101 - Hello, World! (request)",
            connectionEffect: .close
        )
    }
    
    func testObservationAfterUsingEnvironmentInjection() throws {
        struct TestHandler: Handler {
            @Apodini.Environment(\Keys.testObservable) var testObservable
            
            @Apodini.Environment(\.connection) var connection
            
            @State var count: Int = 1
            
            let secondObservable: TestObservable

            func handle() -> Apodini.Response<String> {
                defer {
                    count += 1
                    if testObservable.text == "World" {
                        // should not trigger evaluation
                        testObservable.text = "Cancelled"
                        _testObservable.inject(secondObservable, for: \Keys.testObservable)
                    }
                }
                let response = "\(count): \(testObservable.number) - \(testObservable.text) (\(_testObservable.changed ? "event" : "request"))"
                switch connection.state {
                case .open:
                    return .send(response)
                case .end:
                    return .final(response)
                }
            }
        }
        
        
        let eventLoop = app.eventLoopGroup.next()
        
        let observable = TestObservable()
        let observable2 = TestObservable(100, "Hello, World!")
        let testHandler = TestHandler(secondObservable: observable2).inject(app: app)
        app.storage.set(\Keys.testObservable, to: observable)

        let endpoint = testHandler.mockEndpoint(app: app)

        let exporter = MockExporter<String>()
        let context = endpoint.createConnectionContext(for: exporter)
        
        let listener = TestListener(eventLoop: eventLoop, context: context)
        
        context.register(listener: listener)

        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: eventLoop, final: false),
            content: "1: 0 - Hello (request)",
            connectionEffect: .open
        )
        
        // should trigger second evaluation
        observable.number = 1
        
        XCTAssertNotNil(listener.result)
        XCTAssertEqual(try listener.result!().wait(), "2: 1 - Hello (event)")
        listener.result = nil
        
        // should trigger third evaluation, which triggers another evaluation, but also changes observable object
        observable.text = "World"
        XCTAssertNotNil(listener.result)
        XCTAssertEqual(try listener.result!().wait(), "3: 1 - World (event)")
        // test that the event triggered by the third evaluation was cancelled (this should happen, as at the time it would be
        // evaluated, the @ObservedObject by which the event was observed observes a different observable)
        XCTAssertNotNil(listener.result)
        XCTAssertEqual(try listener.result!().wait(), "Nothing")
        
        listener.result = nil
        
        // should not trigger
        observable.text = "Never"
        XCTAssertNil(listener.result)
        
        // should trigger forth evaluation
        observable2.number = 101
        XCTAssertNotNil(listener.result)
        XCTAssertEqual(try listener.result!().wait(), "4: 101 - Hello, World! (event)")
        listener.result = nil
        
        // final evaluation
        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: eventLoop),
            content: "5: 101 - Hello, World! (request)",
            connectionEffect: .close
        )
    }
    
    
    func testObservationAfterUsingEnvironmentObjectInjection() throws {
        struct TestHandler: Handler {
            @EnvironmentObject var testObservable: TestObservable
            
            @Apodini.Environment(\.connection) var connection
            
            @State var count: Int = 1
            
            let secondObservable: TestObservable
            
            init(secondObservable: TestObservable, testObservableObject: TestObservable) {
                var envObj = EnvironmentObject<TestObservable>()
                envObj.prepareValue(testObservableObject)
                self._testObservable = envObj
                self.secondObservable = secondObservable
            }
            
            func handle() -> Apodini.Response<String> {
                defer {
                    count += 1
                    if testObservable.text == "World" {
                        // should not trigger evaluation
                        testObservable.text = "Cancelled"
                        _testObservable.inject(secondObservable)
                    }
                }
                let response = "\(count): \(testObservable.number) - \(testObservable.text) (\(_testObservable.changed ? "event" : "request"))"
                switch connection.state {
                case .open:
                    return .send(response)
                case .end:
                    return .final(response)
                }
            }
        }
        
        
        let eventLoop = app.eventLoopGroup.next()
        
        let observable = TestObservable()
        let observable2 = TestObservable(100, "Hello, World!")
        let testHandler = TestHandler(secondObservable: observable2, testObservableObject: observable).inject(app: app)
        app.storage.set(\Keys.testObservable, to: observable)

        let endpoint = testHandler.mockEndpoint(app: app)

        let exporter = MockExporter<String>()
        let context = endpoint.createConnectionContext(for: exporter)
        
        let listener = TestListener(eventLoop: eventLoop, context: context)
        
        context.register(listener: listener)

        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: eventLoop, final: false),
            content: "1: 0 - Hello (request)",
            connectionEffect: .open
        )
        
        // should trigger second evaluation
        observable.number = 1
        
        XCTAssertNotNil(listener.result)
        XCTAssertEqual(try listener.result!().wait(), "2: 1 - Hello (event)")
        listener.result = nil
        
        // should trigger third evaluation, which triggers another evaluation, but also changes observable object
        observable.text = "World"
        XCTAssertNotNil(listener.result)
        XCTAssertEqual(try listener.result!().wait(), "3: 1 - World (event)")
        // test that the event triggered by the third evaluation was cancelled (this should happen, as at the time it would be
        // evaluated, the @ObservedObject by which the event was observed observes a different observable)
        XCTAssertNotNil(listener.result)
        XCTAssertEqual(try listener.result!().wait(), "Nothing")
        
        listener.result = nil
        
        // should not trigger
        observable.text = "Never"
        XCTAssertNil(listener.result)
        
        // should trigger forth evaluation
        observable2.number = 101
        XCTAssertNotNil(listener.result)
        XCTAssertEqual(try listener.result!().wait(), "4: 101 - Hello, World! (event)")
        listener.result = nil
        
        // final evaluation
        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: eventLoop),
            content: "5: 101 - Hello, World! (request)",
            connectionEffect: .close
        )
    }
}
