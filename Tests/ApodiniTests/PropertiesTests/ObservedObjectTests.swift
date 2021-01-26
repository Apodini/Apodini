import XCTest
import XCTApodini
import NIO
import Vapor
@testable import Apodini

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
    
    struct Keys: KeyChain {
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
        EnvironmentValues.shared.values.removeAll()
        
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
        EnvironmentValue(\Keys.testObservable, testObservable)
        let handler = TestHandler()
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

            func onObservedDidChange<C: ConnectionContext>(in context: C) {
                _ = context
                    .handle(eventLoop: eventLoop)
                    .map { result in
                        do {
                            let element = try XCTUnwrap(result.element?.typed(String.self))
                            XCTAssertEqual(element, "Hello Swift")
                        } catch {
                            XCTFail("testRegisterObservedListener failed: \(error)")
                        }
                    }
            }
        }

        let exporter = RESTInterfaceExporter(app)
        let handler = TestHandler()
        let endpoint = handler.mockEndpoint()
        var context = endpoint.createConnectionContext(for: exporter)
//        var anyContext = endpoint
//            .createConnectionContext(for: exporter)
//            .eraseToAnyConnectionContext()

        // send initial mock request through context
        // (to simulate connection initiation by client)
        let request = Vapor.Request(
            application: app.vapor.app,
            method: .POST,
            url: URI("http://example.de/test/a?param0=value0"),
            collectedBody: nil,
            on: app.eventLoopGroup.next()
        )
        _ = context.handle(request: request)
//        _ = anyContext.handle(request: request)

        let testObservable = TestObservable()
        EnvironmentValue(\Keys.testObservable, testObservable)
        // register listener
        context.register(listener: TestListener(eventLoop: app.eventLoopGroup.next()))
//        anyContext.register(listener: TestListener(eventLoop: app.eventLoopGroup.next()))
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
            
            func onObservedDidChange<C: ConnectionContext>(in context: C) {
                wasCalled = true
            }
            
            deinit {
                XCTAssertTrue(wasCalled, "Number \(number) failed!")
            }
        }

        let exporter = RESTInterfaceExporter(app)
        let handler = TestHandler()
        
        let endpoint = handler.mockEndpoint()
        var context1 = endpoint.createConnectionContext(for: exporter)
        var context2 = endpoint.createConnectionContext(for: exporter)

        // send initial mock request through context
        // (to simulate connection initiation by client)
        let request = Vapor.Request(
            application: app.vapor.app,
            method: .POST,
            url: URI("http://example.de/test/a?param0=value0"),
            collectedBody: nil,
            on: app.eventLoopGroup.next()
        )
        _ = context1.handle(request: request)
        _ = context2.handle(request: request)

        let testObservable = TestObservable()
        EnvironmentValue(\Keys.testObservable, testObservable)
        // register listener
        context1.register(listener: MandatoryTestListener(eventLoop: app.eventLoopGroup.next(), number: 1))
        context2.register(listener: MandatoryTestListener(eventLoop: app.eventLoopGroup.next(), number: 2))
        // change the value
        testObservable.text = "Hello Swift"
    }
}
