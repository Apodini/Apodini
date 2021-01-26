import XCTest
import XCTApodini
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
        print(app.storage.get(\Keys.testObservable))
        let handler = TestHandler()
        let observedObjects = handler.collectObservedObjects()
        
        XCTAssertNoThrow(handler.handle())
        XCTAssertEqual(observedObjects.count, 1)
        let observedObject = try XCTUnwrap(observedObjects[0] as? ObservedObject<TestObservable>)
        XCTAssert(observedObject.wrappedValue === testObservable)
    }
}
