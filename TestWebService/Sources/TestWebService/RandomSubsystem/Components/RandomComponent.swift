//
//  RamdomComponent.swift
//
//
//  Created by Paul Schmiedmayer on 1/19/21.
//

import Apodini


struct RandomComponent: Component {
    var content: some Component {
        Group("rand") {
            Random()
        }
    }
}
