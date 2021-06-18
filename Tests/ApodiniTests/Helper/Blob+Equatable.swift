//
//  Blob+Equatable.swift
//  
//
//  Created by Paul Schmiedmayer on 6/16/21.
//

import Apodini


extension Blob: Equatable {
    public static func == (lhs: Blob, rhs: Blob) -> Bool {
        lhs.byteBuffer == rhs.byteBuffer && lhs.type == rhs.type
    }
}
