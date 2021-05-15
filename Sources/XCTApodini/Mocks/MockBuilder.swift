//
//  MockBuilder.swift
//  
//
//  Created by Paul Schmiedmayer on 5/12/21.
//


#if DEBUG
#if swift(>=5.4)
@resultBuilder
public enum MockBuilder<Response: Encodable> {}
#else
@_functionBuilder
public enum MockBuilder<Response: Encodable> {}
#endif
extension MockBuilder {
    public static func buildBlock<Response>(_ mocks: Mock<Response>...) -> [Mock<Response>] {
        mocks
    }
}
#endif
