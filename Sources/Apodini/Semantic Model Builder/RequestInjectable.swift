//
//  RequestInjectable.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO


protocol RequestInjectable {
    func inject(using request: Request) throws
}
