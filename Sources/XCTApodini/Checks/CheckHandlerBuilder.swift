//
//  CheckHandlerBuilder.swift
//  
//
//  Created by Paul Schmiedmayer on 5/15/21.
//

#if DEBUG
import Apodini


#if swift(>=5.4)
@resultBuilder
public enum CheckHandlerBuilder {}
#else
@_functionBuilder
public enum CheckHandlerBuilder {}
#endif
extension CheckHandlerBuilder {
    public static func buildBlock(_ anyCheckHandler: AnyCheckHandler...) -> [AnyCheckHandler] {
        anyCheckHandler
    }
}
#endif
