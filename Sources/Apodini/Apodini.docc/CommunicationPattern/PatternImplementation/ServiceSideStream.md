# Service-Side Stream

Provide a code example of service-side stream.

## Overview

A service-side stream sends multiple service-messages after one client-message. In order to do that service-side stream `Handler`s can observe an `ObservableObject` using the `@ObservedObject` property wrapper. Every time one of the properties annotated with `@ObservedObject` changes the `Handler` is evaluated.

The following `Handler` sends out a ping message that is requested by the client. The client could terminate the ping message by closing the connection for protocols or middleware types that support service-side streaming.

```swift
struct TimerObservable: ObservableObject {
    @Published 
    var currentValue: Date = Date()

    private var cancellable: AnyCancellable?

    init() {
        self.cancellable = Timer
            .publish(every: 1)
            .sink { currentValue in
                self.currentValue = currentValue
            }
    }
}

struct Ping: Handler {
    @Parameter var name: String = "Anonymous"
    @ObservedObject var timer = TimerObservable()

    func handle() -> String {
        return "Ping: \(name)"
    }
}
```

`ObservableObject`s can be globally exposed using keypaths.

```swift
class NewsAlertService: ObservableObject {
    @Published var latestAlert: NewsAlert

    // ...
}

struct NewsAlert: Handler {
    @ObservedObject(\.newsAlertService) var newsAlertService: NewsAlertService

    func handle() -> String {
        return newsAlertService.latestAlert.shortSummary
    }
}
```
