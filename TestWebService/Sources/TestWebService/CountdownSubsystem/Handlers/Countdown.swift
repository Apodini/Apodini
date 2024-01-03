//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Apodini

class FakeTimer: Apodini.ObservableObject {
    @Apodini.Published private var _trigger = true
    func secondPassed() {
        Task {
            //try await Task.sleep(nanoseconds: 5000000000)
            _trigger.toggle()
        }
    }
}

struct Countdown: Handler {
    @Parameter(.mutability(.constant)) var start: Int = 10
    @State var counter = -1
    @ObservedObject var timer = FakeTimer()
    
    func handle() -> Apodini.Response<String> {
        timer.secondPassed()
        counter += 1
        if counter == start {
            return .final("🚀🚀🚀 Launch !!! 🚀🚀🚀")
        } else {
            return .send("\(start - counter)...")
        }
    }
    
    var metadata: any AnyHandlerMetadata {
        Pattern(.serviceSideStream)
    }
}
