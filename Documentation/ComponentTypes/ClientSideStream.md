# Client-Side Stream

## Version A: Connection Based Approach

Client-side stream `Component`s are very similar to request-response `Component`s with the difference that they rely on a constant connection that can be observed using the `@Environment` property wrapper:
You can access the connection state using the `Connection`'s `state` property that is retrieved by the `@Environment(\.connection)` property wrapper:

```swift
struct SingleParameterComponent: Component {
    @Parameter var name: String
    @Environemnt(\.connection) var connection: Connection


    func handle() -> String? {
        print(name)

        if connection.state == .end {
            return "End"
        } else { // connection.state == .open
            return nil // Send no reponse to the client as the connection is not yet terminated
        }
    }
}
```

To take full advantage of client-side streams, web services can collect content state from the client across multiple requests using properties annotated with `@Connection`. This functionality is only exposed to Components that support client-side or bidirectional streaming. The `@Connection` is kept in memory as long as the connection is active. The state of the connection can also be determined by accessing the `@Connection` property wrapper `.state` property:

```swift
struct SingleParameterComponent: Component {
    @Parameter var name: String
    @Connection var names: [String]


    func handle() -> String? {
        if $names.state == .open {
            names.append(name)
            return nil
        } else { // $names.connection.state == .end
            return "Hello \(names.joined(seperator: ", "))!"
        }
    }
}
```

## Version B: Collection Based Approach

Client-side stream `Component`s are very similar to request-response `Component`s with the difference that they collect the content from the client before calling the handle method. To indicate that a message can be collected, we mark the property with the `@CollectableParameter`.

```swift
struct SingleParameterComponent: Component {
    @CollectableParameter var names: [String]


    func handle() -> String {
        // Joins all names in the array using commas.
        return "Hello \(names.joined(", "))!"
    }
}
```

 Middlewares and Protocols that don't implement client-side streaming only accept a single request that can include the `@CollectableParameter` as a collection.
 In addition some types might conform to `Collectable` that requires a reduce function:
 ```swift
protocol Collectable {
    associatedtype Value
 

    static var defaultValue: Self.Value { get }


    static func reduce(value: inout Self.Value, nextValue: () -> Self.Value)
}
 ```
This enables `Components` to expose the `@CollectableParameter` as a single type:
```swift
struct NameCollector: Collectable {
    static var defaultValue: String = ""
 

    static func reduce(value: inout String, nextValue: () -> String) {
        value.append(", \(nextValue())")
    }
}

struct SingleParameterComponent: Component {
    @CollectableParameter(NameCollector.self) var names: String


    func handle() -> String {
        return "Hello \(names)!"
    }
}
 ```
