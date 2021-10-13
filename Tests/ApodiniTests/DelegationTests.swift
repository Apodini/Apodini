//
//  DelegationTests.swift
//  
//
//  Created by Max Obermeier on 17.05.21.
//

@testable import Apodini
import ApodiniREST
import XCTApodini
import XCTVapor
import XCTest


final class DelegationTests: XCTApodiniTest {
    private class TestListener: ObservedListener {
        var numbersFired: Int = 0

        func onObservedDidChange(_ observedObject: AnyObservedObject, _ event: TriggerEvent) {
            numbersFired += 1
        }
    }
    
    private class EvaluationCounter {
        var numbersFired: Int = 0
    }
    
    private class TestObservable: Apodini.ObservableObject {
        @Apodini.Published var date: Date
        
        init() {
            self.date = Date()
        }
    }
    
    
    private struct TestDelegate {
        @Parameter var message: String
        @Apodini.Environment(\.connection) var connection
        @ObservedObject var observable: TestObservable
    }
    
    private struct TestHandler: Handler {
        let testDelegate: Delegate<TestDelegate>
        
        @Apodini.Environment(\.connection) var connection
        
        @State var evaluationCounter = EvaluationCounter()
        
        @Parameter var name: String
        @Parameter var sendDate = false
        
        @Throws(.forbidden) var badUserNameError: ApodiniError
        
        
        init(_ observable: TestObservable? = nil) {
            self.testDelegate = Delegate(TestDelegate(observable: observable ?? TestObservable()))
        }
        

        func handle() throws -> Apodini.Response<String> {
            evaluationCounter.numbersFired += 1
            
            guard name == "Paul" else {
                switch connection.state {
                case .open:
                    return .send("Invalid Login")
                case .end:
                    return .final("Invalid Login")
                }
            }
            
            let delegate = try testDelegate()
            
            switch delegate.connection.state {
            case .open:
                return .send(sendDate ? delegate.observable.date.timeIntervalSince1970.description : delegate.message)
            case .end:
                return .final(sendDate ? delegate.observable.date.timeIntervalSince1970.description : delegate.message)
            }
        }
    }
    
    
    func testValidDelegateCall() throws {
        try XCTCheckHandler(TestHandler()) {
            MockRequest(expectation: "Hello, World!") {
                NamedParameter("name", value: "Paul")
                NamedParameter("sendDate", value: false)
                NamedParameter("message", value: "Hello, World!")
            }
        }
    }
    
    func testMissingParameterDelegateCall() {
        XCTAssertThrowsError(
            try XCTCheckHandler(TestHandler()) {
                MockRequest<String>() {
                    NamedParameter("name", value: "Paul")
                }
            }
        )
    }
    
    func testLazynessDelegateCall() throws {
        try XCTCheckHandler(TestHandler()) {
            MockRequest(expectation: "Invalid Login") {
                NamedParameter("name", value: "Not Paul")
            }
        }
    }
    
    func testConnectionAwareDelegate() throws {
        try XCTCheckHandler(TestHandler()) {
            MockRequest(connectionState: .open, expectation: "Hello, Paul!") {
                NamedParameter("name", value: "Paul")
                NamedParameter("sendDate", value: false)
                NamedParameter("message", value: "Hello, Paul!")
            }
            MockRequest(expectation: "Hello, World!") {
                NamedParameter("name", value: "Paul")
                NamedParameter("sendDate", value: false)
                NamedParameter("message", value: "Hello, World!")
            }
        }
    }
    
    func testDelayedActivation() throws {
        var before: TimeInterval?
        
        try XCTCheckHandler(TestHandler()) {
            MockRequest(connectionState: .open, expectation: "Invalid Login") {
                NamedParameter("name", value: "Not Paul")
                NamedParameter("sendDate", value: false)
            }
            ExecuteClosure<String> {
                before = Date().timeIntervalSince1970
            }
            MockRequest<String> { response in
                XCTAssertGreaterThan(try XCTUnwrap(TimeInterval(response)), try XCTUnwrap(before))
            } parameters: {
                NamedParameter("name", value: "Paul")
                NamedParameter("sendDate", value: false)
                NamedParameter("message", value: "Hello, World!")
            }
        }
    }
    
    func testObservability() throws {
        let observable = TestObservable()
        let testListener = TestListener()
        let evaluationCounter = EvaluationCounter()
        
        try XCTCheckHandler(TestHandler(observable)) {
            MockObservedListener<String>(testListener)
            MockRequest(connectionState: .open, expectation: "Invalid Login") {
                NamedParameter("name", value: "Not Paul")
                NamedParameter("sendDate", value: false)
            }
            ExecuteClosure<String> {
                XCTAssertEqual(evaluationCounter.numbersFired, 1)
                XCTAssertEqual(testListener.numbersFired, 0)
                // Should not fire
                observable.date = Date()
            }
            ExecuteClosure<String> {
                // Test that the TestHandler was only fired once after the date was set
                XCTAssertEqual(evaluationCounter.numbersFired, 1)
                // The test listenener should have fired once now
                XCTAssertEqual(testListener.numbersFired, 1)
            }
            // This call is first to invoke delegate
            MockRequest(connectionState: .open, expectation: "Invalid Login") {
                NamedParameter("name", value: "Paul")
                NamedParameter("sendDate", value: true)
                NamedParameter("message", value: "Hello, World!")
            }
            ExecuteClosure<String> {
                XCTAssertEqual(evaluationCounter.numbersFired, 2)
                // Should trigger a third evaluation
                observable.date = Date()
            }
            ExecuteClosure<String> {
                // Test that the TestHandler fired after the date was set
                XCTAssertEqual(evaluationCounter.numbersFired, 3)
                // The test listenener should have fired a second time
                XCTAssertEqual(testListener.numbersFired, 2)
            }
            MockRequest<String>(expectation: "Invalid Login") {
                NamedParameter("name", value: "Not Paul")
                NamedParameter("sendDate", value: false)
            }
        }
    }
    
    func testBindingInjection() throws {
        struct BindingTestDelegate {
            @Binding var number: Int
        }
        
        
        var bindingDelegate = Delegate(BindingTestDelegate(number: Binding.constant(0)))
        bindingDelegate.activate()
        
        bindingDelegate.set(\.$number, to: 1)
        
        let prepared = try bindingDelegate()
        XCTAssertEqual(prepared.number, 1)
    }
    
    func testEnvironmentInjection() throws {
        struct EnvKey: EnvironmentAccessible {
            var name: String
        }
        
        struct NestedEnvironmentDelegate {
            @EnvironmentObject var number: Int
            @Apodini.Environment(\EnvKey.name) var string: String
        }
        
        struct DelegatingEnvironmentDelegate {
            var nestedD = Delegate(NestedEnvironmentDelegate())
            
            func evaluate() throws -> String {
                let nested = try nestedD()
                return "\(nested.string):\(nested.number)"
            }
        }
        
        
        var envDelegat = Delegate(DelegatingEnvironmentDelegate())
        inject(app: app, to: &envDelegat)
        envDelegat.activate()
        
        envDelegat.environment(\EnvKey.name, "Max")
            .environmentObject(1)
        
        let prepared = try envDelegat()
        
        XCTAssertEqual(try prepared.evaluate(), "Max:1")
    }
    
    func testSetters() throws {
        struct BindingObservedObjectDelegate {
            @ObservedObject var observable = TestObservable()
            @Binding var binding: Int
            
            init() {
                _binding = .constant(0)
            }
        }
        
        
        var envDelegate = Delegate(BindingObservedObjectDelegate())
        inject(app: app, to: &envDelegate)
        envDelegate.activate()
        
        let afterInitializationBeforeInjection = Date()
        
        envDelegate
            .set(\.$binding, to: 1)
            .setObservable(\.$observable, to: TestObservable())
        
        let prepared = try envDelegate()
        
        XCTAssertEqual(prepared.binding, 1)
        XCTAssertGreaterThan(prepared.observable.date, afterInitializationBeforeInjection)
    }
    
    func testOptionalOptionality() throws {
        struct OptionalDelegate {
            @Parameter var name: String
        }
        
        struct RequiredDelegatingDelegate {
            let delegate = Delegate(OptionalDelegate())
        }
        
        struct SomeHandler: Handler {
            let delegate = Delegate(RequiredDelegatingDelegate(), .required)
            
            func handle() throws -> some ResponseTransformable {
                try delegate().delegate().name
            }
        }
        
        let parameter = try XCTUnwrap(SomeHandler().buildParametersModel().first as? EndpointParameter<String>)
        
        XCTAssertEqual(ObjectIdentifier(parameter.propertyType), ObjectIdentifier(String.self))
        XCTAssertEqual(parameter.necessity, .required)
        XCTAssertEqual(parameter.nilIsValidValue, false)
        XCTAssertEqual(parameter.hasDefaultValue, false)
        XCTAssertEqual(parameter.option(for: .optionality), .optional)
    }
    
    func testRequiredOptionality() throws {
        struct RequiredDelegate {
            @Parameter var name: String
        }
        
        struct RequiredDelegatingDelegate {
            var delegate = Delegate(RequiredDelegate(), .required)
        }
        
        struct SomeHandler: Handler {
            let delegate = Delegate(RequiredDelegatingDelegate(), .required)
            
            func handle() throws -> some ResponseTransformable {
                try delegate().delegate().name
            }
        }
        
        let parameter = try XCTUnwrap(SomeHandler().buildParametersModel().first as? EndpointParameter<String>)
        
        XCTAssertEqual(ObjectIdentifier(parameter.propertyType), ObjectIdentifier(String.self))
        XCTAssertEqual(parameter.necessity, .required)
        XCTAssertEqual(parameter.nilIsValidValue, false)
        XCTAssertEqual(parameter.hasDefaultValue, false)
        XCTAssertEqual(parameter.option(for: .optionality), .required)
    }
}
