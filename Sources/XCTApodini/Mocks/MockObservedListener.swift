//
//  MockObservedListener.swift
//  
//
//  Created by Paul Schmiedmayer on 5/12/21.
//


#if DEBUG
public class MockObservedListener<R: Encodable & Equatable>: Mock<R> {
    private struct Listener: ObservedListener {
        let eventLoop: EventLoop
        let handler: (EventLoopFuture<Response<EnrichedContent>>) -> ()
        
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
    
    
    override func mock(
        usingConnectionContext context: inout ConnectionContext<MockExporter>?,
        requestNewConnectionContext: () -> (ConnectionContext<MockExporter>),
        eventLoop: EventLoop,
        lastResponse: R?
    ) throws -> R? {
        let response = try super.mock(
            usingConnectionContext: &context,
            requestNewConnectionContext: requestNewConnectionContext,
            eventLoop: eventLoop,
            lastResponse: lastResponse
        )
        
        context?.register(listener: Listener(eventLoop: eventLoop) { responseFuture in
            do {
                let _ = try self.expectation.check(responseFuture)
                self.timeoutExpectation.fulfill()
            } catch {
                XCTFail("Encountered an unexpected error when using an MockObservedListener")
            }
        })
        
        return response
    }
}
#endif
