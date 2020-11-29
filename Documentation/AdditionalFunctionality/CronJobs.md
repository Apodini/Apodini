# CronJobs

`CronJob`s allow to schedule repeating tasks.
These can include running background database operations or fetching data from a remote server.
In Apodini such tasks are defined by conforming to the `CronJob` protocol which includes a `run` method.
This method is executed at scheduled points in time.

## Usage

`CronJob`s can include `@Environment` property wrappers to use other services in the `run` method.
The following example defines a `CronJob` and uses the `@Environment` property wrapper to inject the `NotificationCenter` in order to send out push notifications.

```swift
struct MondayService: CronJob {
    @Environment(\.notificationCenter) notificationCenter: NotificationCenter

    func run() {
        notificationCenter.send(alert: .init(title: "It's monday. The beginning of a new week"), to: "newsletter")
    }
}
```

## Scheduling

Apodini `CronJob`s use the common syntax from (crontab)[https://man7.org/linux/man-pages/man5/crontab.5.html].

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

`CronJob`s are scheduled at server startup from the `configuration` property using the `Schedule` configuration and the cron expression.
When scheduling `CronJob`s, Apodini will create a single instance which can be used with `@Environment` in other components.
In addition, the number of times a `CronJob` is executed can also be defined from `Schedule` configuration.

Let's schedule the previously introduced _MondayService_ to be executed every Monday on 9 am.
We therefore declare this using the `Schedule` configuration.
Furthermore, we specify that the _MondayService_ should only be executed 5 times.

```swift
var configuration: Configuration {
    Schedule(MondayService, on: "0 9 * * 1", runs: 5)
}
```

## Triggering events

Other `Component`s can listen to events that `CronJob`s emit.
Using the `@Published` property wrapper subscribers will be notified everytime one of the annotated properties changes.

In this example the _DateService_ will set a new date every 10 minutes and notify its subscribers.
The _DateComponent_ listens to events of the _DateService_ and will send back responses as a server side stream.

```swift
struct DateService: CronJob {
    @Published date: Date

    func run() {
        date = Date()
    }
}

struct DateComponent: Component {
    @Environment(\.dateService) dateService: DateService

    func handle() -> String {
        "Current date: \($dateService.date)"
    }
}

var configuration: Configuration {
    Schedule(DateService, on: "10 * * * *")
}
```
