# Bidirectional Stream

Provide a code example of bidirectional streams.

<!--
                  
This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT
             
-->

## Overview

The best tools to implement bidirectional streams are `@State` and `@ObservedObject`s.

The following code describes a ping-handler that allows the client to customize the ping-interval at any time.

```swift
struct TimerObservable: ObservableObject {
    @Published 
    var currentValue: Date = Date()

    private var _interval: Int = 1
    var interval: Int {
        set {
            self.cancellable = Timer
                .publish(every: newValue)
                .sink { currentValue in
                    self.currentValue = currentValue
                }
            self._interval = newValue
        }
        get {
            self._interval
        }
    }

    private var cancellable: AnyCancellable = Timer
        .publish(every: 1)
        .sink { currentValue in
            self.currentValue = currentValue
        }
}

struct Ping: Handler {
    @Parameter var interval: Int
    @ObservedObject var timer: TimerObservable

    func handle() -> Response<String> {
        if interval != timer.interval {
            timer.interval = interval
            return .nothing
        }

        return .send("Ping: \(name)")
    }
}
```

## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->
