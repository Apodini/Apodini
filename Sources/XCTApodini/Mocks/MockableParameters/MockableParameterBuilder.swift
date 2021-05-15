//
//  MockableParameterBuilder.swift
//  
//
//  Created by Paul Schmiedmayer on 5/12/21.
//

#if DEBUG
import Apodini


#if swift(>=5.4)
@resultBuilder
public enum MockableParameterBuilder {}
#else
@_functionBuilder
public enum MockableParameterBuilder {}
#endif
extension MockableParameterBuilder {
    public static func buildBlock(_ parameters: MockableParameter...) -> [MockableParameter] {
        parameters
    }
}
#endif
