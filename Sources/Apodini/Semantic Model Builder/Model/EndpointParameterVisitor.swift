//
//  File.swift
//  
//
//  Created by Nityananda on 07.01.21.
//

protocol EndpointParameterVisitor {
    associatedtype Output
    func visit<Element: Codable>(parameter: EndpointParameter<Element>) -> Output
}

protocol EndpointParameterThrowingVisitor {
    associatedtype Output
    func visit<Element: Codable>(parameter: EndpointParameter<Element>) throws -> Output
}
