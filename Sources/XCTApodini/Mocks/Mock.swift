//
//  Mock.swift
//  
//
//  Created by Paul Schmiedmayer on 5/12/21.
//

#if DEBUG
public class Mock<R: Encodable> {
    let options: MockOptions
    
    
    public init(options: MockOptions = .subsequentRequest) {
        self.options = options
    }
    
    
    @discardableResult
    func mock(
        usingConnectionContext context: inout ConnectionContext<MockExporter>?,
        requestNewConnectionContext: () -> (ConnectionContext<MockExporter>),
        eventLoop: EventLoop,
        lastResponse: R?
    ) throws -> R? {
        if context == nil || options.contains(.doNotReuseConnection) {
            context = requestNewConnectionContext()
        }
        
        return lastResponse
    }
}
#endif
