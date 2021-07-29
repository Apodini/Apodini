# Jobs

A gude to schedule repeating tasks in Apodini.

## Overview

`Job`s allow developers to schedule repeating tasks. In contrast to ``Handler``s, `Job`s are not request based.
Use cases for `Job`s could be running background database operations or fetching data from a remote server.
In Apodini such tasks are defined by conforming to the `Job` protocol which includes a `run` method.
This method is executed at scheduled points in time or when triggered by an `ObservedObject`.

## Usage

`Job`s can use all property wrappers that are not connected to incoming requests, e.g. `@Environment`, `@ObservedObject`, and `@State`.

> Tip: Learn more about our communication patterns: <doc:CommunicationPattern>.

The following example defines a `Job` and uses the `@Environment` property wrapper to inject the `NotificationCenter` in order to send out push notifications.

```swift
struct MondayService: Job {
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

`Job`s can be scheduled at server startup from the `configuration` property using the `Schedule` configuration or from an `Handler` by injecting the `Scheduler` with `@Environment`. The `Scheduler` requires as arguments an instance of a `Job`, the cron expression and a corresponding key path conforming to `EnvironmentAccessible`.
When scheduling `Job`s, Apodini will create a single instance which can be used with `@ObservedObject` to listen to changes of properties annotated with `@Published` or when using `@Environment` to read and change properties of a `Job` using the specified key path.

In addition, the number of times a `Job` is executed can also be defined from the `Schedule` configuration.

Let's schedule the previously introduced _MondayService_ to be executed every Monday on 9 am.
We therefore declare this using the `Schedule` configuration and also add a struct _KeyStore_ to define our key path.
Furthermore, we specify that the _MondayService_ should only be executed 5 times.

```swift
struct KeyStore: EnvironmentAccessible {
    var mondayService: MondayService
}

var configuration: Configuration {
    Schedule(MondayService(), on: "0 9 * * 1", runs: 5, \KeyStore.mondayService)
}
```

We also want to add a `Handler` to manually execute the _MondayService_ and to cancel any further execution. Injecting the `Job` to the `Handler` allows us to execute the `run` method. Using the `Scheduler` in a `Handler` we can dequeue the `Job` with the corresponding key path.

```swift
struct MondayServiceHandler: Handler {
    @Environment(\KeyStore.mondayService) var mondayService: MondayService

    func handle() -> String {
        mondayService.run()
        return "Executed"
    }
}

struct CancelHandler: Handler {
    @Environment(\.scheduler) var scheduler: Scheduler

    func handle() -> String {
        scheduler.dequeue(\KeyStore.mondayService)
        return "Cancelled"
    }
}

```

## Triggering events

Other `Handler`s can listen to events that `Job`s emit.
Using the `@Published` property wrapper subscribers will be notified everytime one of the annotated properties changes.

In this example the _DateService_ will set a new date every 10 minutes and notify its subscribers.
The _DateHandler_ listens to events of the _DateService_ and will send back responses as a service-side stream.

```swift
struct DateService: Job {
    @Published var date = Date()

    func run() {
        date = Date()
    }
}

struct DateHandler: Handler {
    @ObservedObject(\.dateService) var dateService: DateService

    func handle() -> String {
        "Current date: \($dateService.date)"
    }
}

var configuration: Configuration {
    Schedule(DateService(), on: "*/10 * * * *")
}
```

## Subscribing to events

Besides emitting events, `Job`s can also listen to changes of other ``ObservedObject` which are declared with the `@ObservedObject` property wrapper.
This will also trigger the `run` method of a `Job`.
To differentiate between the scheduled execution and the execution of an `ObservableObject`, the projected Boolean value `changed` of the property wrapper can be used. Projected values of property wrappers are accessed using the `$` prefix operator.

The _RegisterHandler_ is responsible to count every access to its path and store this information in _VisitorObservedObject_. Using `Environment(value, keyPath)` in the `configuration` stored property, which takes as arguments a key path and the corresponding value, we can declare the _VisitorObservedObject_ as a Singleton. This allows us to use the `ObservableObject` in the web service with the property wrappers `@Environment` and `@ObservedObject` and the key path. The `Job` will send a weekly push notification based on the total number of visitors and also when someone accessed the _RegisterHandler_ by listening to changes to the _VisitorObservedObject_. To differentiate between these two cases we use the property `changed` of `@ObservedObject`  to check if the `Job` was triggered by being scheduled or by the _VisitorObservedObject_.

```swift
struct TestWebService: WebService {
    struct VisitorObservedObject: ObservableObject {
        @Published var count = 0
    }

    struct SummaryJob: Job {
        @ObservedObject(\KeyStore.visitorObservedObject) var visitors: VisitorObservedObject

        @Environment(\.notificationCenter) var notificationCenter: NotificationCenter

        func run() {
            if _visitors.changed {
                notificationCenter.send(alert: Alert(title: "We have a new customer"), to: "visitorTopic")
            } else {
                notificationCenter.send(alert: Alert(title: "This week we had a total of \(visitorObject.count) visitors", to: "visitorTopic"))
            }
        }
    }

    struct RegisterHandler: Handler {
        @Environment(\KeyStore.visitorObservedObject) var visitors: VisitorObservedObject

        func handle() -> String {
            visitors.count += 1
            return "Welcome to our site!"
        }
    }

    var content: some Component {
        RegisterHandler()
    }

    var configuration: Configuration {
        EnvironmentObject(VisitorObservedObject(), \KeyStore.visitorObservedObject)
        Schedule(SummaryJob(), on: "0 9 * * 5", \KeyStore.summaryJob)
    }

    struct KeyStore: EnvironmentAccessible {
        var visitorObservedObject: VisitorObservedObject
        var summaryJob: SummaryJob
    }
}
```

## Topics

### Implementation

- <doc:PushNotifications>

