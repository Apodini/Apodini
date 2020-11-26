# Push Notifications

The `NotificationCenter` handles the registration and sending of **push notifications** to Apple Push Notification Service (APNS) and Firebase Cloud Messaging (FCM). APNS can send out push notifications to iOS, macOS and tvOS devices, while FCM handles messaging for iOS, Android and Web Push.

## Configuration

In order to send push notifications, the Apodini web server needs to be authenticated to at least one push notification service. These services are added to a web server by defining them in the `configuration` computed property.

This example adds APNS to the web server.

```swift
var configuration: some Configuration {
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
public struct Device: Content {
    public var type: PushNotificationService
    public var token: String
    public var subscriptions: [String]?
}

public enum PushNotificationService: String {
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

    func handle() -> EventLoopFuture<Bool> {
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
    public var alert: Alert
    public var payload: Payload
    public var data: Encodable
}
```

Example of a `Component` that sends a push notification to an user:

```swift
struct SendNotification: Component {
    @Request(\.user) var user: User

    @Environment(\.notificationCenter) var notificationCenter: NotificationCener

    func handle() -> EventLoopFuture<Bool> {
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

Events can trigger the sending of push notifications. This builds on top of `Component`s and follows the same approach as **[Service-Side Stream Components](../ComponentTypes/ServiceSideStream.md)** with `ObservableObject`s. `Component`s subscribe to `ObservableObject`s that are exposed to the environment. The handle method of the `Component` will be executed every time `@Published` properties of the `ObservableObject` change. `ObservableObject`s also can be scheduled as **[CronJobs](./CronJob.md)**.

The following example shows a _WeatherService_ as a `CronJob` that fetches the weather every day and publishes it to its subscribers using the `@Published` property wrapper. The _AlertComponent_ listens to changes of the _WeatherService_ and sends out push notification based on the current weather. Every `Device` with the **subscription** _weatherSubscription_ will receive this push notification.

```swift
struct WeatherService: ObservedObject {
    @Published var weather = "sunny"

    handle() {
        // Updates weather
    }
}

struct AlertComponent: Component {
    @Environment(\.notificationCenter) var notificationCenter: NotificationCener

    @Environment(\.) var weatherService: WeatherService

    func handle() -> EventLoopFuture<Bool> {
        notificationCenter.send(notification: .init(title: "The weather today will be \($weatherService.weather)"), to: "weatherSubscription")
    }
}
```
