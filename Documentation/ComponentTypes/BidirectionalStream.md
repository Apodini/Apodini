# Bidirectional Stream

Bidirectional streams introduce the interesting challenge that a `Component` needs to save state across different client-side requests to decide when to send out responses. We achieve this using an `@State` property wrapper.
The following example showcases a component that collects messages and returns them in separate messages on a `"Send"` command received from the client.

```swift
struct SavingAndSendComponent: Component {
    @Parameter var command: AnyPublisher<String, Never>
    @State var savedCommands: [String] = []


    func handle() -> throws AnyPublisher<String, Never>? {
        guard command == "Send" else {
              savedCommands += command
            // We use the `Apodini.NoResponse()` error to indicate that there is no response at this time
            return nil
        }

        // Creates a publisher that sends out each message saved in the `savedCommands` array seperately
        return Just(savedCommands)
            .split()
    }
}
```
For middlewares or protocols that don't support bidirectional streaming, the interface is exposed similar to a request-response component. The client can send messages to the `Componenmechanismthe commands are saved the same way as service communication mechanim that offers a constant connection. The serice side stream is returned the same way as described in the section about service-side steam `Component`s. Subsequent requests to the same endpoint must be supported by a session identifier or a user that is authenticated with the requests. Otherwise, the endpoint and not be exposed to protocols or middlewares that don't support client-side streams.

A second example would be a `Compoent` that allows the user to create separate times in a single open communication channel:
```swift
struct MultipleTimerComponent: Component {
    // Used to stop a timer for a specific ID.
    @Parameter var timerID: UUID?
    // Saves the times as long as the connection is open
    @State var timers: [UUID: Timer] = [:]


    func handle() -> throws AnyPublisher<String, Never>? {
        if let timerID = timerID, let timer = timers[timerID] {
            timer.stop()
            return nil
        }

        let timerID = UUID()
        let timer = Timer(every: 1.0)
        timers[timerID] = timer

        return timer
            .publisher()
            .map {
                "Ping: \(timerID)"
            }
    }
}
```
