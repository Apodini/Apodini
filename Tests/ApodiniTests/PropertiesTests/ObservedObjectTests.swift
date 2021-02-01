import XCTest
import XCTApodini
import NIO
import Vapor
@testable import Apodini
import Foundation

class ObservedObjectTests: ApodiniTests {
    // check setting changed
    class TestObservable: Apodini.ObservableObject {
        @Apodini.Published var number: Int
        @Apodini.Published var text: String
        
        init() {
            number = 0
            text = "Hello"
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
        let observedObjects = handler.collectObservedObjects()
        
        XCTAssertEqual(observedObjects.count, 1)
        XCTAssert(observedObjects[0] is ObservedObject<TestObservable>)
    }
    
    func testObservedObjectEnvironmentInjection() throws {
        struct TestHandler: Handler {
            @ObservedObject(\Keys.testObservable) var testObservable: TestObservable
            
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
        handler = handler.inject(app: app)
        
        let observedObjects = handler.collectObservedObjects()
        
        XCTAssertNoThrow(handler.handle())
        XCTAssertEqual(observedObjects.count, 1)
        let observedObject = try XCTUnwrap(observedObjects[0] as? ObservedObject<TestObservable>)
        XCTAssert(observedObject.wrappedValue === testObservable)
    }
    
    func testRegisterObservedListener() {
        struct TestHandler: Handler {
            @ObservedObject(\Keys.testObservable) var testObservable: TestObservable
            
            func handle() -> String {
                testObservable.text
            }
        }
        
        struct TestListener: ObservedListener {
            var eventLoop: EventLoop
            
            func onObservedDidChange<C: ConnectionContext>(_ observedObject: AnyObservedObject, in context: C) {
                do {
                    try context
                        .handle(eventLoop: eventLoop, observedObject: observedObject)
                        .map { result in
                            do {
                                let element = try XCTUnwrap(result.element?.typed(String.self))
                                XCTAssertEqual(element, "Hello Swift")
                            } catch {
                                XCTFail("testRegisterObservedListener failed: \(error)")
                            }
                        }
                        .wait()
                } catch {
                    XCTFail(error.localizedDescription)
                }
            }
        }
        
        let exporter = RESTInterfaceExporter(app)
        let handler = TestHandler()
        let endpoint = handler.mockEndpoint(app: app)
        var context = endpoint.createConnectionContext(for: exporter)
        var anyContext = endpoint
            .createConnectionContext(for: exporter)
            .eraseToAnyConnectionContext()
        
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
        _ = context.handle(request: request)
        _ = anyContext.handle(request: request)
        
        // register listener
        context.register(listener: TestListener(eventLoop: app.eventLoopGroup.next()))
        anyContext.register(listener: TestListener(eventLoop: app.eventLoopGroup.next()))
        // change the value
        testObservable.text = "Hello Swift"
    }
    
    func testObservedListenerNotShared() {
        struct TestHandler: Handler {
            @ObservedObject(\Keys.testObservable) var testObservable: TestObservable
            
            func handle() -> String {
                testObservable.text
            }
        }
        
        class MandatoryTestListener: ObservedListener {
            var eventLoop: EventLoop
            
            var wasCalled = false
            
            let number: Int
            
            init(eventLoop: EventLoop, number: Int) {
                self.eventLoop = eventLoop
                self.number = number
            }
            
            func onObservedDidChange<C: ConnectionContext>(_ observedObject: AnyObservedObject, in context: C) {
                wasCalled = true
            }
            
            deinit {
                XCTAssertTrue(wasCalled, "Number \(number) failed!")
            }
        }
        
        let exporter = RESTInterfaceExporter(app)
        let handler = TestHandler()
        
        let endpoint = handler.mockEndpoint(app: app)
        var context1 = endpoint.createConnectionContext(for: exporter)
        var context2 = endpoint.createConnectionContext(for: exporter)
        
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
        context1.register(listener: MandatoryTestListener(eventLoop: app.eventLoopGroup.next(), number: 1))
        context2.register(listener: MandatoryTestListener(eventLoop: app.eventLoopGroup.next(), number: 2))
        // change the value
        testObservable.text = "Hello Swift"
    }
    
    func testChangedProperty() throws {
        let testObservable = TestObservable()
        
        struct TestHandler: Handler {
            @ObservedObject(\Keys.testObservable) var observable: TestObservable
            
            @State var shouldBeTriggeredByObservedObject = false
            
            func handle() -> String {
                XCTAssertEqual(_observable.changed, shouldBeTriggeredByObservedObject)
                shouldBeTriggeredByObservedObject.toggle()
                return observable.text
            }
        }
        
        struct TestListener: ObservedListener {
            var eventLoop: EventLoop
            
            init(eventLoop: EventLoop) {
                self.eventLoop = eventLoop
            }
            
            func onObservedDidChange<C: ConnectionContext>(_ observedObject: AnyObservedObject, in context: C) {
                do {
                    try context
                        .handle(eventLoop: eventLoop, observedObject: observedObject)
                        .map { result in
                            do {
                                let element = try XCTUnwrap(result.element?.typed(String.self))
                                XCTAssertEqual(element, "Hello Swift")
                            } catch {
                                XCTFail("testRegisterObservedListener failed: \(error)")
                            }
                        }
                        .wait()
                } catch {
                    XCTFail(error.localizedDescription)
                }
            }
        }
        app.storage.set(\Keys.testObservable, to: testObservable)
        
        let exporter = RESTInterfaceExporter(app)
        let handler = TestHandler()
        
        let endpoint = handler.mockEndpoint(app: app)
        var context = endpoint.createConnectionContext(for: exporter)
        
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
        context.register(listener: TestListener(eventLoop: app.eventLoopGroup.next()))
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
        var context = endpoint.createConnectionContext(for: exporter)
        
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
}
