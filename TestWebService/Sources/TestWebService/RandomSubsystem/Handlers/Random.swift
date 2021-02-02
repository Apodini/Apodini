//
//  Random.swift
//  
//
//  Created by Paul Schmiedmayer on 1/19/21.
//

import Apodini

struct Random: Handler {
    @Parameter var number = Int.random()

    func handle() -> Int {
        number
    }
}
