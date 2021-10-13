//
//  MockableParameterBuilder.swift
//  
//
//  Created by Paul Schmiedmayer on 5/12/21.
//

import Apodini


@resultBuilder
public enum MockableParameterBuilder {
    public static func buildBlock(_ parameters: MockableParameter...) -> [MockableParameter] {
        parameters
    }
}
