# Unsolicited Event

In Contrast to all other communication mechanisms, unsolicited events build on top of the existing `Component` structure and can be built into every component. The core component is an `EventManager` that is part of the `@Environment`.

The event type is defined by the `EventType` protocol:
```swift
public protocol EventType {
    associatedtype Message
    associatedtype Address
    
    static var id: String { get }
    static var address: KeyPath<User, [Address]> { get }
}
```

An event type can conform to `EventType` and specifies the `Message` type and the `address`es that the message should be sent to.

```swift
struct ExampleEventMessage {
    var content: String
}

struct ExampleEventType: EventType {
    typealias Message = ExampleEventMessage
    typealias Address = User
    
    static var id = "com.schmiedmayer.eventTypeOne"
    static var address = \User.apnsIDs
}
```

To understand how unsolicited events are sent out, first let's take a look at a Component that sends out a message using the `EventMenager` based on an incoming request: The `EventMenager` is injected by the communication protocols or middleware based on a configuration provided by the maintainer of the web service. You use a service-side stream to register for an event. Based on the middleware/protocol implementation the service-side stream or an external channel can be used to provide the events.

```swift
struct RegisterForEventBasedAction: Component {
    @Parameter var apnsID: String?
    @Environment(.\user) var user: User
    @Environment(.\eventManager) var eventManager: EventManager

    func handle() -> AnyPublisher<ExampleEventMessage, Never> {
        if let apnsIDs = apnsIDs {
            user.apnsIDs.append(apnsID)
            user.save()
        }

        return eventManager.registered(for: ExampleEventType.self)
    }
}


struct EventSenderComponent: Component {
    @Parameter var name: String
    @Environment(.\user) var user: User
    @Environment(.\eventManager) var eventManager: EventManager


    func handle() -> String {
        eventManager.send(ExampleEventType.self, 
                         content: ExampleEventMessage("Hello world!!")
                         to: user)
        return "Send out an event message!"
    }
}
```

An event message could also be sent out without a message from the user if e.g., a `Timer` would be used in the registered `Component`.
