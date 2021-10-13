//
//  CheckHandlerBuilder.swift
//  
//
//  Created by Paul Schmiedmayer on 5/15/21.
//

import Apodini


@resultBuilder
public enum CheckHandlerBuilder {
    public static func buildBlock(_ anyCheckHandler: AnyCheckHandler...) -> [AnyCheckHandler] {
        anyCheckHandler
    }
}
