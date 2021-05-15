//
//  ExecuteClosure.swift
//  
//
//  Created by Paul Schmiedmayer on 5/12/21.
//

#if DEBUG
public class ExecuteClosure<R: Encodable & Equatable>: Mock<R> {
    let closure: () -> ()
    
    public init(options: MockOptions = .subsequentRequest, closure: @escaping () -> ()) {
        self.closure = closure
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
        
        closure()
        
        return response
    }
}
#endif
