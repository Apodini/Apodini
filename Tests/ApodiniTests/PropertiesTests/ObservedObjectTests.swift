@testable import Apodini
@testable import ApodiniREST
import Vapor
import Foundation
import XCTApodini


class ObservedObjectTests: ApodiniTests {
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
            @Apodini.Environment(\Keys.testObservable) var testObservable: TestObservable
            
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
            
            var context: ConnectionContext<RESTInterfaceExporter, TestHandler>

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
        
        let exporter = RESTInterfaceExporter(app)
        let handler = TestHandler()
        let endpoint = handler.mockEndpoint(app: app)
        let context = endpoint.createConnectionContext(for: exporter)

        let request = Vapor.Request(
            application: app.vapor.app,
            method: .POST,
            url: URI("http://example.de/test/a?param0=value0"),
            collectedBody: nil,
            on: app.eventLoopGroup.next()
        )
        
        // initialize the observable object
        let testObservable = TestObservable()
        
        app.storage.set(\Keys.testObservable, to: testObservable)
        
        // send initial mock request through context
        // (to simulate connection initiation by client)
        _ = try context.handle(request: request).wait()

        // register listener
        context.register(listener: TestListener(eventLoop: app.eventLoopGroup.next(), context: context))
        // change the value
        testObservable.text = "Hello Swift"
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
            
            var context: ConnectionContext<RESTInterfaceExporter, TestHandler>
            
            var wasCalled = false
            
            let number: Int
            
            init(eventLoop: EventLoop, number: Int, context: ConnectionContext<RESTInterfaceExporter, TestHandler>) {
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
        
        let exporter = RESTInterfaceExporter(app)
        let handler = TestHandler()

        let endpoint = handler.mockEndpoint(app: app)
        let context1 = endpoint.createConnectionContext(for: exporter)
        let context2 = endpoint.createConnectionContext(for: exporter)

        let request = Vapor.Request(
            application: app.vapor.app,
            method: .POST,
            url: URI("http://example.de/test/a?param0=value0"),
            collectedBody: nil,
            on: app.eventLoopGroup.next()
        )
        
        let testObservable = TestObservable()
        app.storage.set(\Keys.testObservable, to: testObservable)
        
        // send initial mock request through context
        // (to simulate connection initiation by client)
        _ = context1.handle(request: request)
        _ = context2.handle(request: request)
        
        // register listener
        context1.register(listener: MandatoryTestListener(eventLoop: app.eventLoopGroup.next(), number: 1, context: context1))
        context2.register(listener: MandatoryTestListener(eventLoop: app.eventLoopGroup.next(), number: 2, context: context2))
        // change the value
        testObservable.text = "Hello Swift"
    }
    
    func testChangedProperty() throws {
        let testObservable = TestObservable()
        
        struct TestHandler: Handler {
            @Apodini.Environment(\Keys.testObservable) var observable: TestObservable
            
            @State var shouldBeTriggeredByObservedObject = false
            
            func handle() -> String {
                XCTAssertEqual(_observable.changed, shouldBeTriggeredByObservedObject)
                shouldBeTriggeredByObservedObject.toggle()
                return observable.text
            }
        }
        
        struct TestListener: ObservedListener {
            var eventLoop: EventLoop
            
            var context: ConnectionContext<RESTInterfaceExporter, TestHandler>
            
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
        
        let exporter = RESTInterfaceExporter(app)
        let handler = TestHandler()

        let endpoint = handler.mockEndpoint(app: app)
        let context = endpoint.createConnectionContext(for: exporter)

        // send initial mock request through context
        // (to simulate connection initiation by client)
        let request = Vapor.Request(
            application: app.vapor.app,
            method: .POST,
            url: URI("http://example.de/test/a?param0=value0"),
            collectedBody: nil,
            on: app.eventLoopGroup.next()
        )
        _ = try context.handle(request: request).wait()
        
        // register listener
        context.register(listener: TestListener(eventLoop: app.eventLoopGroup.next(), context: context))
        // change the value
        testObservable.text = "Hello Swift"
        
        // evaluate handler again to check `changed` was reset
        _ = try context.handle(request: request).wait()
    }
    
    func testDeferredDefualtValueInitialization() throws {
        class InitializationObserver: Apodini.ObservableObject {
            @Apodini.Published var date = Date()
        }
        
        struct TestHandler: Handler {
            @ObservedObject var observable = InitializationObserver()
            
            func handle() -> String {
                XCTAssertLessThan(Date().timeIntervalSince1970 - observable.date.timeIntervalSince1970, TimeInterval(0.1))
                return "\(observable.date)"
            }
        }
        
        let exporter = RESTInterfaceExporter(app)
        let handler = TestHandler()
        
        // We wait 0.1 seconds after creating the handler so the assertion in the
        // handler would fail if the stub InitializationObserver was created right
        // with the handler.
        usleep(100000)
        
        let endpoint = handler.mockEndpoint(app: app)
        let context = endpoint.createConnectionContext(for: exporter)
        
        // send initial mock request through context
        // (to simulate connection initiation by client)
        let request = Vapor.Request(
            application: app.vapor.app,
            method: .POST,
            url: URI("http://example.de/test/a?param0=value0"),
            collectedBody: nil,
            on: app.eventLoopGroup.next()
        )
        _ = try context.handle(request: request).wait()
    }
    
    
    class TestListener<H: Handler>: ObservedListener {
        var eventLoop: EventLoop
        
        var context: ConnectionContext<MockExporter<String>, H>
        
        var result: (() -> EventLoopFuture<String>)?
        
        init(eventLoop: EventLoop, context: ConnectionContext<MockExporter<String>, H>) {
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
