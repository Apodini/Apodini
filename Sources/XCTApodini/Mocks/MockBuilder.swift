//
//  MockBuilder.swift
//  
//
//  Created by Paul Schmiedmayer on 5/12/21.
//


@resultBuilder
public enum MockBuilder<Response: Encodable> {
    public static func buildBlock<Response>(_ mocks: Mock<Response>...) -> [Mock<Response>] {
        mocks
    }
}
