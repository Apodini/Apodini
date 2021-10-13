//
//  MockObservedListener.swift
//
//
//  Created by Paul Schmiedmayer on 5/12/21.
//

import Apodini


/// An object that can be called whenever a ``TriggerEvent`` is raised.
public protocol ObservedListener {
    /// The function to be called whenever a ``TriggerEvent`` is raised.
    func onObservedDidChange(_ observedObject: AnyObservedObject, _ event: TriggerEvent)
}


public class MockObservedListener<R: Encodable & Equatable>: Mock<R> {
    private struct Listener: ObservedListener {
        let timeoutExpectation: XCTestExpectation?
        let listener: ObservedListener
        
        
        func onObservedDidChange(_ observedObject: AnyObservedObject, _ event: TriggerEvent) {
            timeoutExpectation?.fulfill()
            listener.onObservedDidChange(observedObject, event)
        }
    }
    
    private let listener: Listener
    
    
    public init(
        _ listener: ObservedListener,
        timeoutExpectation: XCTestExpectation? = XCTestExpectation(description: "MockObservedListener was expected to be fired at least once"),
        options: MockOptions = .subsequentRequest
    ) {
        self.listener = Listener(timeoutExpectation: timeoutExpectation, listener: listener)
        super.init(options: options)
    }
    
    
    override func mock(usingExporter exporter: MockInterfaceExporter, mockIdentifier: MockIdentifier, lastResponse: R?) throws -> R? {
        try exporter.register(listener, toHandlerIdentifiedBy: mockIdentifier)
        return lastResponse
    }
}


public class _MockObservedListener<R: Encodable & Equatable>: Mock<R> {
    private struct Listener: ObservedListener {
        let eventLoop: EventLoop
        let handler: (EventLoopFuture<Response<R>>) -> ()
        
        func onObservedDidChange(_ observedObject: AnyObservedObject, _ event: TriggerEvent) {
            timeoutExpectation?.fulfill()
            listener.onObservedDidChange(observedObject, event)
        }
        func onObservedDidChange(_ observedObject: AnyObservedObject, in context: ConnectionContext<MockExporter>) {
            handler(context.handle(eventLoop: eventLoop, observedObject: observedObject))
        }
    }
    
    private let expectation: Expectation<R>
    private let timeoutExpectation: XCTestExpectation
    
    
    public init(_ expectation: Expectation<R>, timeoutExpectation: XCTestExpectation, options: MockOptions = .subsequentRequest) {
        self.expectation = expectation
        self.timeoutExpectation = timeoutExpectation
        
        super.init(options: options)
    }
    
    
    override func mock(usingExporter exporter: MockInterfaceExporter, mockIdentifier: MockIdentifier, lastResponse: R?) throws -> R? {
        exporter.register(
            Listener(eventLoop: eventLoop) { esponseFuture in
                do {
                    let _ = try self.expectation.check(responseFuture)
                    self.timeoutExpectation.fulfill()
                } catch {
                    XCTFail("Encountered an unexpected error when using an MockObservedListener")
                }
            },
            toHandlerIdentifiedBy: mockIdentifier
        )
        
        return lastResponse
    }
}
