//
// Created by Andreas Bauer on 25.12.20.
//

@testable import Apodini

struct PrintGuard: SyncGuard {
    func check() {
        print("PrintGuard check executed")
    }
}
