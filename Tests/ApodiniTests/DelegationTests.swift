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
import ApodiniUtils


final class DelegationTests: ApodiniTests {
    class TestObservable: Apodini.ObservableObject {
        @Apodini.Published var date: Date
        
        init() {
            self.date = Date()
        }
    }
    
    
    struct TestDelegate: PropertyIterable {
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
            
            let delegate = try testD.instance()
            
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
    
    class TestListener<H: Handler>: ObservedListener where H.Response.BodyContent: StringProtocol {
        var eventLoop: EventLoop
        
        var context: ConnectionContext<String, H>
        
        var result: EventLoopFuture<TimeInterval>?
        
        init(eventLoop: EventLoop, context: ConnectionContext<String, H>) {
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
    
    struct BindingTestDelegate: PropertyIterable {
        @Binding var number: Int
    }
    
    func testBindingInjection() throws {
        var bindingD = Delegate(BindingTestDelegate(number: Binding.constant(0)))
        bindingD.activate()
        
        let connection = Connection(request: MockRequest.createRequest(running: app.eventLoopGroup.next()))
        bindingD.inject(connection, for: \Apodini.Application.connection)
        
        bindingD.set(\.$number, to: 1)
        
        let prepared = try bindingD.instance()
        
        XCTAssertEqual(prepared.number, 1)
    }
    
    struct EnvKey: EnvironmentAccessible {
        var name: String
    }
    
    struct NestedEnvironmentDelegate: PropertyIterable {
        @EnvironmentObject var number: Int
        @Apodini.Environment(\EnvKey.name) var string: String
    }
    
    struct DelegatingEnvironmentDelegate: PropertyIterable {
        var nestedD = Delegate(NestedEnvironmentDelegate())
        
        func evaluate() throws -> String {
            let nested = try nestedD.instance()
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
        
        let prepared = try envD.instance()
        
        XCTAssertEqual(try prepared.evaluate(), "Max:1")
    }
    
    func testSetters() throws {
        struct BindingObservedObjectDelegate: PropertyIterable {
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
        
        let prepared = try envD.instance()
        
        XCTAssertEqual(prepared.binding, 1)
        XCTAssertGreaterThan(prepared.observable.date, afterInitializationBeforeInjection)
    }
    
    func testOptionalOptionality() throws {
        struct OptionalDelegate: PropertyIterable {
            @Parameter var name: String
        }
        
        struct RequiredDelegatingDelegate: PropertyIterable {
            var delegate = Delegate(OptionalDelegate())
        }
        
        struct SomeHandler: Handler {
            var delegate = Delegate(RequiredDelegatingDelegate(), .required)
            
            func handle() throws -> some ResponseTransformable {
                try delegate
                    .instance()
                    .delegate
                    .instance()
                    .name
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
        struct RequiredDelegate: PropertyIterable {
            @Parameter var name: String
        }
        
        struct RequiredDelegatingDelegate: PropertyIterable {
            var delegate = Delegate(RequiredDelegate(), .required)
        }
        
        struct SomeHandler: Handler {
            var delegate = Delegate(RequiredDelegatingDelegate(), .required)
            
            func handle() throws -> some ResponseTransformable {
                try delegate
                    .instance()
                    .delegate
                    .instance()
                    .name
            }
        }
        
        let parameter = try XCTUnwrap(SomeHandler().buildParametersModel().first as? EndpointParameter<String>)
        
        XCTAssertEqual(ObjectIdentifier(parameter.propertyType), ObjectIdentifier(String.self))
        XCTAssertEqual(parameter.necessity, .required)
        XCTAssertEqual(parameter.nilIsValidValue, false)
        XCTAssertEqual(parameter.hasDefaultValue, false)
        XCTAssertEqual(parameter.option(for: .optionality), .required)
    }
    
    func testDelegateIsNamingBarrier() {
        struct NameChecker: DynamicProperty {
            @Binding var wasExecuted: Box<Bool>
            
            func namingStrategy(_ names: [String]) -> String? {
                XCTAssertEqual(names, ["checker", "x"])
                wasExecuted.value = true
                return names.last
            }
        }
        
        struct DelegateWithNameChecker: PropertyIterable {
            var checker: NameChecker
        }
        
        struct DelegatingObject: DynamicProperty {
            var delegate: Delegate<DelegateWithNameChecker>
        }
        
        struct DelegatingObjectWrappingObject: PropertyIterable {
            var delegatingObject: DelegatingObject
        }
        
        var instance = DelegatingObjectWrappingObject(
            delegatingObject: DelegatingObject(
                delegate: Delegate(DelegateWithNameChecker(
                    checker: NameChecker(wasExecuted: .constant(Box(false)))))))
        
        exposedApply({ (_: inout BoolCarrier, name: String) in
            XCTAssertEqual(name, " x")
        }, to: &instance)
        
        exposedExecute({ (_: BoolCarrier, name: String) in
            XCTAssertEqual(name, "x")
        }, on: instance)
    }
}

private protocol BoolCarrier { }

extension Binding: BoolCarrier where Value == Box<Bool> { }
