//
// Created by Andreas Bauer on 25.12.20.
//

@testable import Apodini

struct PrintGuard: Guard {
    func check() {
        print("PrintGuard check executed")
    }
}
