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
        
        init() {
            number = 0
            text = "Hello"
        }
    }
    
    struct Keys: EnvironmentAccessible {
        var testObservable: TestObservable
    }
    
    struct TestHandler: Handler {
        @ObservedObject(\Keys.testObservable) var testObservable: TestObservable
        
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
    
    func testRegisterObservedListener() throws {
        let testObservable = TestObservable()
        app.storage.set(\Keys.testObservable, to: testObservable)
        
        let expectation = XCTestExpectation(description: "Observation is executed")
        expectation.assertForOverFulfill = true
        
        try newerXCTCheckHandler(TestHandler()) {
            MockRequest(expectation: "Hello")
            MockObservedListener(.response("Hello Swift"), timeoutExpectation: expectation)
            ExecuteClosure<String> {
                testObservable.text = "Hello Swift"
            }
            MockRequest(expectation: "Hello Swift")
        }
        
        wait(for: [expectation], timeout: 0)
    }
    
    func testObservedListenerNotShared() throws {
        let testObservable = TestObservable()
        app.storage.set(\Keys.testObservable, to: testObservable)
        
        let firstExpectation = XCTestExpectation(description: "Observation is executed")
        firstExpectation.assertForOverFulfill = true
        let secondExpectation = XCTestExpectation(description: "Observation is executed")
        secondExpectation.assertForOverFulfill = true
        
        try newerXCTCheckHandler(TestHandler()) {
            MockRequest(expectation: "Hello")
            MockObservedListener(.response("Hello Swift"), timeoutExpectation: firstExpectation)
        }
        
        try newerXCTCheckHandler(TestHandler()) {
            MockRequest(expectation: "Hello")
            MockObservedListener(.response("Hello Swift"), timeoutExpectation: secondExpectation)
        }
        
        testObservable.text = "Hello Swift"
        wait(for: [firstExpectation, secondExpectation], timeout: 0)
    }
    
    func testChangedProperty() throws {
        struct TestHandler: Handler {
            @ObservedObject(\Keys.testObservable) var observable: TestObservable
            
            func handle() -> Bool {
                _observable.changed
            }
        }
        
        let testObservable = TestObservable()
        app.storage.set(\Keys.testObservable, to: testObservable)
        
        let expectation = XCTestExpectation(description: "Observation is executed")
        expectation.assertForOverFulfill = true
        
        try newerXCTCheckHandler(TestHandler()) {
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
        
        try newerXCTCheckHandler(TestHandler()) {
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
        
        try newerXCTCheckHandler(TestHandler()) {
            MockRequest(expectation: 42)
            MockObservedListener(.response(-1), timeoutExpectation: expectation)
            ExecuteClosure<Int> {
                InitializationObserver.updateLatestCreatedInitializationObserver()
            }
            MockRequest(expectation: -1)
        }
        
        wait(for: [expectation], timeout: 0)
    }
}
