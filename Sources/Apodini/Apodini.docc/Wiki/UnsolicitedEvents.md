# Handling Unsolicited Events

Handling Unsolicited Events

When writing `Job`s, or `Handler`s with a persistent connection, there is a good change you will need unsolicited events. Events cause Apodini to evaluate those types. For `Job`s an _event_ can either be a **schedule** or a change on an `ObservableObject`. `Handler`s are also evaluated in the latter case, and when a request arrives.

This section is about `ObservableObject`s and how you can use them to trigger an evaluation of your application logic.

### TL;DR

It works just as in SwiftUI, except we use a custom implementation of `ObservableObject` and `@Published` instead of Combine's.

### Emitting _Events_

Any `class` can be an `ObservableObject` without having to implement anything. It only means that it makes sense to observe this object. You'll learn how to observe an `ObservableObject` below. However, first we have to emit _events_ from the `ObservableObject`. This can be done by changing the value of a `@Published` property on the `ObservableObject`.

```swift
class Contact: ObservableObject {
    // not wrapped with `@Published`
    var name: String
    // wrapped with `@Published`
    @Published var age: Int

    init(name: String, age: Int) {
        self.name = name
        self.age = age
    }

    func haveBirthday() -> Int {
        age += 1
        return age
    }

    func changeName(to name: String) {
        self.name = name
    }
}
```
In this example, a call to `haveBirthday()` would emit an _event_, whereas `changeName(to:)` won't.

You can have as many `@Published` properties on an `ObservableObject` as you want, however, they have to be **directly** on the `ObservableObject`, i.e. they cannot be wrapped in another type.

`@Published` does not check for equality, that is setting the following would still emit an _event_:

```swift
let john = Contact(name: "John Appleseed", age: 24)
john.age = john.age
```

### Handling _Events_

There are multiple ways to make Apodini observe an `ObservableObject`. They all work the same, the only difference is how they are initialised.

#### `@ObservedObject`

To use an `@ObservedObject` you have to provide an initial value.

Here is a small example on how you could use `@ObservedObject` on a `Handler` with persistent connection:

```swift
/// After the client connects to this endpoint, the `Stopwatch` sends a message
/// containing the `TimeInterval` since the last incoming request every 100ms.
struct Stopwatch: Handler {
    @ObservedObject var tick: Timer = Timer(100)

    @State var start: Date = Date()

    @Environment(\.connection) var connection

    func handle() -> Response<TimeInterval> {
        // the client has signalled they want to close the connection
        guard connection.state == .open else {
            return .end
        }

        // we check `$tick.changed` to find out if the current evaluation
        // was caused by a request or the `Timer`
        if !$tick.changed {
            // if the evaluation was not caused by the `Timer` we reset the
            // `Stopwatch`
            start = Date()
            tick = Timer(100)
        }
        return .send(Date().timeIntervalSince(start))
    }
}
```

#### `@EnvironmentObject`

`@EnvironmentObject` does not require an initial value in its initialiser. Instead, you are responsible to inject an object of the right type into the local environment via a `Delegate`. See more on how this works in [Delegating Handlers](./Delegating-Handlers)

```swift
@EnvironmentObject var myObjectFromLocalEnvironment: SomeType
```


_**WARNING: If you forget to inject a value at some point, your program will crash when accessing the `@EnvironmentObject`'s `wrappedValue`!**_

#### `@Environment`

`@Environment` is very similar to `@EnvironmentObject` with two differences:
* Injected values are not identified by their type, but based on the `KeyPath` you pass to the initialiser.
* `@Environment` also refers to the global environment if there is no fitting value available in the local environment.

```swift
@Environment(\Some.keyPath) var myObjectFromLocalOrGlobalEnvironment
```

_**WARNING: Again, if you forget to inject a value at some point, your program will crash when accessing the `@Environment`'s `wrappedValue`!**_


[//]: # (TODO: link to `EnvironmentValue`)

### _Event_ Cancellation and `.changed` Property

When you change the value of a `@Published` property, its value changes immediately and this can also be perceived when accessing the value via `ObservedObject`, `EnvironmentObject` or `Environment` on a `Handler`. However, the evaluation that is triggered by the change is done asynchronically. That is, the following sequence of events is possible:

1. `@Published` property is changed
2. `Handler` is evaluated because of a _request event_
3. `Handler` is evaluated because of the change to the `@Published` property (_unsolicited event_)

In step 2, you can already see that the actual value has changed, however the `.changed` property of the `ObservedObject`/`EnvironmentObject`/`Environment` you are accessing the `ObservableObject` through is still `false`. The `.changed` property is only set `true` for step 3 (in a synchronous manner).

Moreover, in step 2, the evaluation could cause the `ObservableObject` to be replaced by a different `ObservableObject`. In that case, the _unsolicited event_ would be cancelled and step 3 would be omitted.

## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->
