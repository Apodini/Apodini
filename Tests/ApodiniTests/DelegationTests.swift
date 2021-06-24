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


final class DelegationTests: ApodiniTests {
    class TestObservable: Apodini.ObservableObject {
        @Apodini.Published var date: Date
        
        init() {
            self.date = Date()
        }
    }
    
    
    struct TestDelegate {
        @Parameter var message: String
        @Apodini.Environment(\.connection) var connection
        @ObservedObject var observable: TestObservable
    }
    
    struct TestHandler: Handler {
        let testD: Delegate<TestDelegate>
        
        @Parameter var name: String
        
        @Parameter var sendDate = false
        
        @Throws(.forbidden) var badUserNameError: ApodiniError
        
        @Apodini.Environment(\.connection) var connection
        
        init(_ observable: TestObservable? = nil) {
            self.testD = Delegate(TestDelegate(observable: observable ?? TestObservable()))
        }

        func handle() throws -> Apodini.Response<String> {
            guard name == "Max" else {
                switch connection.state {
                case .open:
                    return .send("Invalid Login")
                case .end:
                    return .final("Invalid Login")
                }
            }
            
            let delegate = try testD()
            
            switch delegate.connection.state {
            case .open:
                return .send(sendDate ? delegate.observable.date.timeIntervalSince1970.description : delegate.message)
            case .end:
                return .final(sendDate ? delegate.observable.date.timeIntervalSince1970.description : delegate.message)
            }
        }
    }

    func testValidDelegateCall() throws {
        var testHandler = TestHandler().inject(app: app)
        activate(&testHandler)

        let endpoint = testHandler.mockEndpoint(app: app)

        let exporter = MockExporter<String>(queued: "Max", false, "Hello, World!")
        let context = endpoint.createConnectionContext(for: exporter)
        
        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next()),
            content: "Hello, World!",
            connectionEffect: .close
        )
    }
    
    func testMissingParameterDelegateCall() throws {
        var testHandler = TestHandler().inject(app: app)
        activate(&testHandler)

        let endpoint = testHandler.mockEndpoint(app: app)

        let exporter = MockExporter<String>(queued: "Max")
        let context = endpoint.createConnectionContext(for: exporter)
        
        XCTAssertThrowsError(try context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next()).wait())
    }
    
    func testLazynessDelegateCall() throws {
        var testHandler = TestHandler().inject(app: app)
        activate(&testHandler)

        let endpoint = testHandler.mockEndpoint(app: app)

        let exporter = MockExporter<String>(queued: "Not Max")
        let context = endpoint.createConnectionContext(for: exporter)
        
        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next()),
            content: "Invalid Login",
            connectionEffect: .close
        )
    }
    
    func testConnectionAwareDelegate() throws {
        var testHandler = TestHandler().inject(app: app)
        activate(&testHandler)

        let endpoint = testHandler.mockEndpoint(app: app)

        let exporter = MockExporter<String>(queued: "Max", false, "Hello, Paul!", "Max", false, "Hello, World!")
        let context = endpoint.createConnectionContext(for: exporter)
        
        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next(), final: false),
            content: "Hello, Paul!",
            connectionEffect: .open
        )
        
        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next()),
            content: "Hello, World!",
            connectionEffect: .close
        )
    }
    
    func testDelayedActivation() throws {
        var testHandler = TestHandler().inject(app: app)
        activate(&testHandler)

        let endpoint = testHandler.mockEndpoint(app: app)

        let exporter = MockExporter<String>(queued: "Not Max", false, "Max", true, "")
        let context = endpoint.createConnectionContext(for: exporter)

        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next(), final: false),
            content: "Invalid Login",
            connectionEffect: .open
        )
        
        let before = Date().timeIntervalSince1970
        // this call is first to invoke delegate
        let response = try context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next()).wait()
        let observableInitializationTime = TimeInterval(response.content!)!
        XCTAssertGreaterThan(observableInitializationTime, before)
    }
    
    class TestListener<H: Handler>: ObservedListener where H.Response.Content: StringProtocol {
        var eventLoop: EventLoop
        
        var context: ConnectionContext<MockExporter<String>, H>
        
        var result: EventLoopFuture<TimeInterval>?
        
        init(eventLoop: EventLoop, context: ConnectionContext<MockExporter<String>, H>) {
            self.eventLoop = eventLoop
            self.context = context
        }

        func onObservedDidChange(_ observedObject: AnyObservedObject, _ event: TriggerEvent) {
            result = context.handle(eventLoop: eventLoop, observedObject: observedObject, event: event).map { response in
                TimeInterval(response.content!)!
            }
        }
    }
    
    func testObservability() throws {
        let eventLoop = app.eventLoopGroup.next()
        
        let observable = TestObservable()
        var testHandler = TestHandler(observable).inject(app: app)
        activate(&testHandler)

        let endpoint = testHandler.mockEndpoint(app: app)
        
        let exporter = MockExporter<String>(queued: "Not Max", false, "Max", true, "", "Max", true, "", "Not Max", false)
        let context = endpoint.createConnectionContext(for: exporter)
        
        let listener = TestListener<TestHandler>(eventLoop: eventLoop, context: context)

        context.register(listener: listener)

        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: eventLoop, final: false),
            content: "Invalid Login",
            connectionEffect: .open
        )
        
        // should not fire
        observable.date = Date()
        
        // this call is first to invoke delegate
        _ = try context.handle(request: "Example Request", eventLoop: eventLoop, final: false).wait()
        
        // should trigger third evaluation
        let date = Date()
        observable.date = date
        
        let result = try listener.result?.wait()
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, date.timeIntervalSince1970)
        
        // final evaluation
        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: eventLoop),
            content: "Invalid Login",
            connectionEffect: .close
        )
    }
    
    struct BindingTestDelegate {
        @Binding var number: Int
    }
    
    func testBindingInjection() throws {
        var bindingD = Delegate(BindingTestDelegate(number: Binding.constant(0)))
        bindingD.activate()
        
        let connection = Connection(request: MockRequest.createRequest(running: app.eventLoopGroup.next()))
        bindingD.inject(connection, for: \Apodini.Application.connection)
        
        bindingD.set(\.$number, to: 1)
        
        let prepared = try bindingD()
        
        XCTAssertEqual(prepared.number, 1)
    }
    
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
    
    func testEnvironmentInjection() throws {
        var envD = Delegate(DelegatingEnvironmentDelegate())
        inject(app: app, to: &envD)
        envD.activate()
        
        let connection = Connection(request: MockRequest.createRequest(running: app.eventLoopGroup.next()))
        envD.inject(connection, for: \Apodini.Application.connection)
        
        envD
            .environment(\EnvKey.name, "Max")
            .environmentObject(1)
        
        let prepared = try envD()
        
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
        
        
        var envD = Delegate(BindingObservedObjectDelegate())
        inject(app: app, to: &envD)
        envD.activate()
        
        let connection = Connection(request: MockRequest.createRequest(running: app.eventLoopGroup.next()))
        envD.inject(connection, for: \Apodini.Application.connection)
        
        let afterInitializationBeforeInjection = Date()
        
        envD
            .set(\.$binding, to: 1)
            .setObservable(\.$observable, to: TestObservable())
        
        let prepared = try envD()
        
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
