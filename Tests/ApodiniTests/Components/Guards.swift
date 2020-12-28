//
// Created by Andi on 25.12.20.
//

@testable import Apodini

struct PrintGuard: SyncGuard {
    @_Request
    var request: ApodiniRequest

    func check() {
        print(request)
    }
}
