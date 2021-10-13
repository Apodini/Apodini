//
//  ExecuteClosure.swift
//  
//
//  Created by Paul Schmiedmayer on 5/12/21.
//


public class ExecuteClosure<R: Encodable & Equatable>: Mock<R> {
    private let closure: (R?) throws -> ()
    
    
    public init(options: MockOptions = .subsequentRequest, closure: @escaping (R?) -> ()) {
        self.closure = closure
        super.init(options: options)
    }
    
    public init(options: MockOptions = .subsequentRequest, closure: @escaping () -> ()) {
        self.closure = { _ in closure() }
        super.init(options: options)
    }
    
    
    override func mock(
        usingExporter exporter: MockInterfaceExporter,
        mockIdentifier: MockIdentifier,
        lastResponse: R?
    ) throws -> R? {
        try closure(lastResponse)
        return lastResponse
    }
}
