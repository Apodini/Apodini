# Service-Side Stream

## Version A - The Publisher: 

Service-side stream `Component`s look and behave the same way as simple request-response `Component` regarding their properties. Server-Streaming components can not save any state as client-side steam `Compoenent`s can.  
In contrast to request-response `Compoent`s, service-side stream `Component`s return a Combine `AnyPublisher` that allows a component to send out one or multiple responses. Once the `Publisher` is terminated, the connection to the client is closed.  
To read up about Combine `Publishers`, you can take a look at the [Combine Book](https://heckj.github.io/swiftui-notes/#coreconcepts) or the basics by John Sundell article found at [https://www.swiftbysundell.com/basics/combine/](https://www.swiftbysundell.com/basics/combine/).
Using `Publisher`s allows the component to express multiple responses emitted based on one request over time, and terminating a connection is directly tied to the lifetime of the returned `Publisher`.

The following `Component` sends out a ping message that is requested by the client. The client could terminate the ping message by closing the connection for protocols or middleware types that support service-side streaming.


```swift
struct PingComponent: Component {
    @Parameter var name: String = "Paul"


    func handle() -> AnyPublisher<String, Never> {
        Timer.publish(every: 1)
            .map {
                "Ping: \(name)"
            }
    }
}
```

External services exposing a publisher could be brought into the component using custom user defined key paths that extend the default Apodini `@Environment`.

```swift
class NewsAlertService: ObservableObject {
    @Published var latestAlert: NewsAlert

    // ...
}

struct NewsAlertComponent: Component {
    @Environment(\.newsAlertService) var newsAlertService: NewsAlertService

    func handle() -> AnyPublisher<String, Never> {
        newsAlertService.objectWillChange
            .debounce(for: 60.0) // Collapses multiple news alerts within 60 seconds in a single value
            .map {
                newsAlertService.shortSummary
            }
    }
}
```

Protocols or middlewares that don't support service-side streams such as REST will only return all values that are available on the first sink execution and terminate the publisher at that point. E.g., in our example, only one ping message is sent out or just the latest newsAlert is send to the client

`Component`s can also merge multiple publishers:

```swift
class NewsAlertService: ObservableObject {
    @Published var latestAlert: NewsAlert

    // ...
}

class CoolPictureService: ObservableObject {
    @Published var coolPicture: Image

    // ...
}

struct NewsAlertComponent: Component {
    @Environment(\.newsAlertService) var newsAlertService: NewsAlertService
    @Environment(\.coolImageService) var coolImageService: CoolPictureService

    func handle() -> AnyPublisher<AlertWithImage, Never> {
        newsAlertService.objectWillChange
            .combineLatest(coolImageService.objectWillChange) { (alert, image) in
                return AlertWithImage(alert, image)
            }
    }
}
```

## Version B - The Observer: 

Service-side stream `Component`s look and behave the same way as simple request-response `Component` regarding their properties. Server-Streaming components can not save any state as client-side steam `Compoenent`s can.  
In contrast to request-response `Compoent`s, service-side stream `Component`s can observe an `ObservableObject` using the `@ObservedObject` property wrapper. Every time one of the properties annotated with `@ObservedObject` changes the `handle` method will be called.

The following `Component` sends out a ping message that is requested by the client. The client could terminate the ping message by closing the connection for protocols or middleware types that support service-side streaming.

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

struct PingComponent: Component {
    @Parameter var name: String = "Paul"
    @ObservedObject var timer: TimerObservable

    func handle() -> String {
        return "Ping: \(name)"
    }
}
```

Services that are exposed in the Environment are automatically observed and the handle method is called every time the `NewsAlertService`'s objectWillChange that is automatically synthesized for `ObservableObject`s fires.

```swift
class NewsAlertService: ObservableObject {
    @Published var latestAlert: NewsAlert

    // ...
}

struct NewsAlertComponent: Component {
    @Environment(\.newsAlertService) var newsAlertService: NewsAlertService

    func handle() -> String {
        // Collapses multiple news alerts within 60 seconds in a single value is not easily possible as we do not have an overview of a stream of events but is a simpler implementation in the handle method.
        return newsAlertService.latestAlert.shortSummary
    }
}
```

*Open question: How would Apodini be able to differentiate between a normal request response component and a service-side stream?*
*Open question: How would Apodini enable wait for for multipe ObservedObjects and how would one detect which of the `@ObservedObject`s has changed?*
