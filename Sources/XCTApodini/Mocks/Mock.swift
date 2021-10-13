//
//  Mock.swift
//  
//
//  Created by Paul Schmiedmayer on 5/12/21.
//


public class AnyMock {
    func anyMock(usingExporter exporter: MockInterfaceExporter, mockIdentifier: MockIdentifier, lastResponse: Any?) throws -> Any? {
        nil
    }
}


public class Mock<R: Encodable>: AnyMock {
    let options: MockOptions
    
    
    public init(options: MockOptions = .subsequentRequest) {
        self.options = options
    }
    
    
    func mock(usingExporter exporter: MockInterfaceExporter, mockIdentifier: MockIdentifier, lastResponse: R?) throws -> R? {
        nil
    }
    
    
    override func anyMock(usingExporter exporter: MockInterfaceExporter, mockIdentifier: MockIdentifier, lastResponse: Any?) throws -> Any? {
        try mock(usingExporter: exporter, mockIdentifier: mockIdentifier, lastResponse: lastResponse as? R)
    }
}
