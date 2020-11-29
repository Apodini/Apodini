# Push Notifications

The `NotificationCenter` handles the registration and sending of **push notifications** to Apple Push Notification Service (APNS) and Firebase Cloud Messaging (FCM). APNS can send out push notifications to iOS, macOS and tvOS devices, while FCM handles messaging for iOS, Android and Web Push.

## Configuration

In order to send push notifications, the Apodini web server needs to be authenticated to at least one push notification service. These services are added to a web server by defining them in the `configuration` computed property.

This example adds APNS to the web server.

```swift
var configuration: Configuration {
    APNSConfiguration(.pem(pemPath: "certificate.pem"), identifier: "de.tum.in.ase.Example", environment: .sandbox)
}
```

## Usage

The `NotificationCenter` can be injected to any `Component` by using the `@Environment` property wrapper.

```swift
struct NewsAlertComponent: Component {
    @Environment(\.notificationCenter) var notificationCenter: NotificationCener

    // ...
}
```

## Device Registration

Devices can be registered to the `NotificationCenter` by conforming to the `Device` protocol. This protocol consists of the following proerties:

- **type**: This property specifies which push notification service to use.
- **token**: The device id for one app used by the push notification service
- **subscriptions**: Subscriptions are used to group `Device`s together. Example: All devices that want to receive news alerts for a specific topic.

```swift
public struct Device {
    public var type: PushNotificationService
    public var token: String
    public var subscriptions: [String]?
}

public enum PushNotificationService {
    case apns
    case fcm
}
```

The web service needs a specific route and `Component` to handle push notification registration. The following example shows how to add a `Device` to the currently authenticated `User`.

```swift
struct RegisterComponent: Component {
    @Request(\.user) var user: User  // The logged in user

    @Parameter var device: Device  // The `Device` instance in a request body

    @Environment(\.notificationCenter) var notificationCenter: NotificationCener

    func handle() -> EventLoopFuture<Void> {
        notificationCenter.register(device, to: user);
    }
}
```

Furthermore, the `NotificationCenter` allows the removal and editing of `Device`s.

## Sending Push Notifications

`Notification`s are structured as follows:

- **alert**: Displayed message on the device which includes title, subtitle, and body.
- **payload**: Service specific notification settings like sound, badges, images, etc.
- **data**: Background data.

`Notification`s don't have to include an alert and can just send a silent push notification with background data.

```swift
public struct Notification {
    public var alert: Alert?
    public var payload: Payload?
    public var data: Encodable?
}
```

Example of a `Component` that sends a push notification to an user:

```swift
struct SendNotification: Component {
    @Request(\.user) var user: User

    @Environment(\.notificationCenter) var notificationCenter: NotificationCener

    func handle() -> EventLoopFuture<Void> {
        notificationCenter.send(alert: .init(title: "Hello There 👋"), to: user)
    }
}
```

The `NotificationCenter` offers the following convenience methods to send push notifications:

- Send to all registered devices
- Send to a subscription
- Send to all devices of a user
- Send to multiple users
- Send to a specific device
- Send to a specific token

## Unsolicited Push Notifications

Events in Apodini can trigger the sending of push notifications. `Component`s can subscribe to `ObservableObject`s or **[CronJobs](./CronJob.md)** that are exposed to the environment. The `handle` method of a `Component` will be executed every time `@Published` properties of the `ObservableObject` or `CronJob` change. Unsolicited `Component`s are defined in Apodini by conforming to the `EventComponent` protocol. This specifies that `EventComponent`s are only executed by events which the `EventComponent` subscribes to, whereas incoming requests of clients will not be handled. Therefore, property wrappers that are request based, e.g. `@Request` or `@Parameter`, cannot be used in an `EventComponent` and will throw an error. This also means that Apodini exporters will ignore this `Component`.

The following example shows a _WeatherService_ as a `CronJob` that fetches the weather every day at 10 am and publishes it to its subscribers using the `@Published` property wrapper. The _AlertComponent_ listens to changes of the _WeatherService_ and sends out push notifications based on the current weather. Every `Device` with the **subscription** _weatherSubscription_ will receive this push notification.

```swift
struct WeatherService: CronJob {
    @Published var weather = "sunny"

    func run() {
        // Updates weather
    }
}

struct AlertComponent: EventComponent {
    @Environment(\.notificationCenter) var notificationCenter: NotificationCener

    @Environment(\.weatherService) var weatherService: WeatherService

    func handle() {
        notificationCenter.send(notification: .init(title: "The weather today will be \($weatherService.weather)"), to: "weatherSubscription")
    }
}

var content: some Component {
    AlertComponent()
    // ...
}

var configuration: Configuration {
    Schedule(WeatherService, on: "0 10 * * *")
}
```
