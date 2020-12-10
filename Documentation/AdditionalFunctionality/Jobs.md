![document type: vision](https://apodini.github.io/resources/markdown-labels/document_type_vision.svg)

# Jobs

`Job`s allow to schedule repeating tasks and are in contrast to `Component`s not request based.
Use cases for `Job`s could be running background database operations or fetching data from a remote server.
In Apodini such tasks are defined by conforming to the `Job` protocol which includes a `run` method.
This method is executed at scheduled points in time or when triggered by an [ObservableObject](<./../Communicational\ Patterns/2.\ Tooling/2.4.\ ObservedObject.md>).

## Usage

`Job`s can include the `@Environment` property wrappers to use other services in the `run` method.
The following example defines a `Job` and uses the `@Environment` property wrapper to inject the `NotificationCenter` in order to send out push notifications.

```swift
struct MondayService: CronJob {
    @Environment(\.notificationCenter) var notificationCenter: NotificationCenter

    func run() {
        notificationCenter.send(alert: .init(title: "It's monday. The beginning of a new week"), to: "newsletter")
    }
}
```

## Scheduling

Apodini `Job`s can be scheduled using the common syntax from [crontab](https://man7.org/linux/man-pages/man5/crontab.5.html).

```
┌───────────── minute (0 - 59)
│  ┌───────────── hour (0 - 23)
│  │  ┌───────────── day of the month (1 - 31)
│  │  │  ┌───────────── month (1 - 12)
│  │  │  │  ┌───────────── day of the week (0 - 6)
│  │  │  │  │              (Sunday to Saturday)
│  │  │  │  │
│  │  │  │  │
\* \* \* \* \*
```

`Job`s are scheduled at server startup from the `configuration` property using the `Schedule` configuration and the cron expression.
When scheduling `Job`s, Apodini will create a single instance which can be used with `@ObservedObject` in other components.
In addition, the number of times a `Job` is executed can also be defined from the `Schedule` configuration.

Let's schedule the previously introduced _MondayService_ to be executed every Monday on 9 am.
We therefore declare this using the `Schedule` configuration.
Furthermore, we specify that the _MondayService_ should only be executed 5 times.

```swift
var configuration: Configuration {
    Schedule(MondayService.self, on: "0 9 * * 1", runs: 5)
}
```

## Triggering events

Other `Component`s can listen to events that `Job`s emit.
Using the `@Published` property wrapper subscribers will be notified everytime one of the annotated properties changes.

In this example the _DateService_ will set a new date every 10 minutes and notify its subscribers.
The _DateComponent_ listens to events of the _DateService_ and will send back responses as a service-side stream.

```swift
struct DateService: Job {
    @Published var date = Date()

    func run() {
        date = Date()
    }
}

struct DateComponent: Component {
    @ObservedObject(\.dateService) var dateService: DateService

    func handle() -> String {
        "Current date: \($dateService.date)"
    }
}

var configuration: Configuration {
    Schedule(DateService.self, on: "10 * * * *")
}
```

## Subscribing to events

Besides emitting events, `Job`s can also listen to changes of other [ObservedObjects](<./../Communicational\ Patterns/2.\ Tooling/2.4.\ ObservedObject.md>) which are declared with the `@ObservedObject` property wrapper.
This will also trigger the `run` method of a `Job`.
To differentiate between the scheduled execution and the execution of an `ObservableObject`, the projected Boolean value `changed` of the property wrapper can be used. Projected values of property wrappers are accessed using the `$` prefix operator.

Consider the following example which consists of a `Component` called _RegisterComponent_, a `Job` _SummaryJob_, and an `ObservableObject` _VisitorObservedObject_.  
The _RegisterComponent_ is responsible to count every access to its path and store this information in _VisitorObservedObject_. Using `Environment(keypath, value)` in the `configuration` stored property, which takes as arguments a keypath and the corresponding value, we can declare the _VisitorObservedObject_ as a Singleton. This allows us to use the `ObservableObject` in the web service with the property wrappers `@Environment` and `@ObservedProperty` and the keypath. The `Job` will send a weekly push notification based on the total number of visitors and also when someone accessed the _RegisterComponent_ by listening to changes to the _VisitorObservedObject_. To differentiate between these two cases we use the projected value `$visitors.changed` to check if the `Job` was triggered by being scheduled or by the _VisitorObservedObject_.

```swift
struct TestWebService: WebService {
    struct VisitorObservedObject: ObservableObject {
        @Published var count = 0
    }

    struct SummaryJob: Job {
        @ObservedObject(\.visitorObservedObject) var visitors: VisitorObservedObject

        @Environment(\.notificationCenter) var notificationCenter: NotificationCenter

        func run() {
            if $visitors.changed {
                notificationCenter.send(alert: Alert(title: "We have a new customer"), to: "visitorTopic")
            } else {
                notificationCenter.send(alert: Alert(title: "This week we had a total of \(visitorObject.count) visitors", to: "visitorTopic"))
            }
        }
    }

    struct RegisterComponent: Component {
        @Environment(\.visitorObservedObject) var visitors: VisitorObservedObject

        func handle() -> String {
            visitors.count += 1
            return "Welcome to our site!"
        }
    }

    var content: some Component {
        RegisterComponent()
    }

    var configuration: Configuration {
        Environment(\.visitorObservedObject, VisitorObservedObject())
        Schedule(SummaryJob.self, on: "0 9 * * 5")
    }
}
```
