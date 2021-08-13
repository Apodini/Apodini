# Stateful Handlers

Usually endpoints only handle one request and answer with one response. However, in certain cases, this is not enough. Apodini sets no restrictions on this.

## Overview

Apodini's API for handling requests is the ``Handler`` protocol. And that doesn't change if you want to get more than a single request-response cycle. Apodini defines a special ``Response`` type and additional ``Property``s to help you in achieving exactly the behavior you want.

### The Connection

Once we leave the idea of a single request-response cycle behind, we talk about a connection. A request-response cycle is the shortest form of a connection. A connection always starts with a request and ends with a response, but there could be multiple messages heading either direction in between. In order to perceive the ``Connection`` in your application logic, you can use the ``Environment`` with `KeyPath` ``Application/connection``. The most important part about the ``Connection`` is its ``Connection/state``. It tells you if the client has finished sending requests, or not.

The rule is that your ``Handler`` is evaluated once for each request and at least once with ``Connection/state`` being ``ConnectionState/end``. For each evaluation of the ``Handler``, you return a ``Response``. Returning ``Response/nothing``, means the evaluation should not result in a response being sent to the client. Returning ``Response/send(_:information:)-72126`` results in the content being sent to the client. However, the connection is not closed. With ``Response/final(_:information:)-6pe1o``, you can send content and close the connection. Finally, ``Response/end`` closes the connection without sending an additional response.

For example, the following ``Handler`` greets each `name` that is sent to it in a bidirectional connection.

```swift
struct Greeter: Handler {
    @Parameter var name: String

    @Environment(\.connection) var connection

    func handle() -> Response<String> {
        if connection.state == .open {
            return .send("Hello, \(name)!")
        } else {
            return .end
        }
    }
}
```

> Note: ``Handler``s where the connection may consist of more than one request are always evaluated more than once. That is because Apodini is middleware-agnostic. In order to get consistency, exporters should always evaluate the ``Handler`` once for every request, plus one additional final evaluation with ``Connection/state`` on ``ConnectionState/end``.

### Maintaining State

If the connection consists of multiple requests, you most likely want to maintain state across evaluations of your ``Handler``. This can be done just as in SwiftUI with ``State``.

```swift
struct Greeter: Handler {
    @Parameter var name: String

    @Environment(\.connection) var connection

    @State var names: [String] = []

    func handle() -> Response<String> {
        if connection.state == .open {
            names.append(name)
            return .nothing
        } else {
            return .final("Hello, \(names.joined(separator: ", "))!")
        }
    }
}
```

> Tip: By wrapping ``State`` and ``Parameter`` into one ``DynamicProperty``, you can often hide some complexity from your ``Handler/handle()-3440f`` function.

### Handling Unsolicited Events

When writing ``Handler``s with a persistent connection, there is a good chance you will need unsolicited events. Events cause Apodini to evaluate the ``Handler``. ``Handler``s are evaluated when a request arrives, or when an ``ObservableObject`` - which is observed by the ``Handler`` - changes.

Let's look at how you can create ``ObservableObject``s and how you can use them to trigger an evaluation of your application logic.

#### TL;DR

It works just as in SwiftUI, except we use a custom implementation of ``ObservableObject`` and ``Published`` instead of Combine's.

#### Emitting _Events_

Any `class` can be an ``ObservableObject`` without having to implement anything. It only means that it makes sense to observe this object. You'll learn how to observe an ``ObservableObject`` below. However, first we have to emit _events_ from the ``ObservableObject``. This can be done by changing the value of a ``Published`` property on the ``ObservableObject``.

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

You can have as many ``Published`` properties on an ``ObservableObject`` as you want, however, they have to be **directly** on the ``ObservableObject``, i.e. they cannot be wrapped in another type.

``Published`` does not check for equality, that second line below would still emit an _event_:

```swift
let john = Contact(name: "John Appleseed", age: 24)
john.age = john.age
```

#### Handling _Events_

There are multiple ways to make Apodini observe an ``ObservableObject``. They all work the same, the only difference is how they are initialized.

##### @ObservedObject

To use an ``ObservedObject`` you have to provide an initial value.

Here is a small example on how you could use ``ObservedObject`` on a ``Handler`` with persistent connection:

```swift
/// After the client connects to this endpoint, the `Stopwatch` sends a message
/// containing the `TimeInterval` since the last incoming request every 100ms.
struct Stopwatch: Handler {
    @ObservedObject var tick: Timer = Timer(100)

    @State var start: Date = Date()

    @Environment(\.connection) var connection

    func handle() -> Response<TimeInterval> {
        // the client has signaled they want to close the connection
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

##### @EnvironmentObject

``EnvironmentObject`` does not require an initial value in its initializer. Instead, you are responsible to inject an object of the right type into the local environment via a ``Delegate``. See more on how this works in <doc:AllAboutReuse>.

```swift
@EnvironmentObject var myObjectFromLocalEnvironment: SomeType
```


> Warning: If you forget to inject a value at some point, your program will crash when accessing the ``EnvironmentObject``'s `wrappedValue`!

##### @Environment

``Environment`` is very similar to ``EnvironmentObject`` with two differences:
* Injected values are not identified by their type, but based on the `KeyPath` you pass to the initializer.
* ``Environment`` also refers to the global environment (i.e. ``EnvironmentValue``s) if there is no fitting value available in the local environment.

```swift
@Environment(\Some.keyPath) var myObjectFromLocalOrGlobalEnvironment
```

> Warning: Again, if you forget to inject a value at some point, your program will crash when accessing the ``Environment``'s `wrappedValue`!


#### _Event_ Cancellation

When you change the value of a ``Published`` property, its value changes immediately and this can also be perceived when accessing the value via ``ObservedObject``, ``EnvironmentObject`` or ``Environment`` on a ``Handler``. However, the evaluation that is triggered by the change is done asynchronically. That is, the following sequence of events is possible:

1. ``Published`` property is changed
2. ``Handler`` is evaluated because of a _request event_
3. ``Handler`` is evaluated because of the change to the ``Published`` property (_unsolicited event_)

In step 2, you can already see that the actual value has changed, however the `.changed` property of the ``ObservedObject``/``EnvironmentObject``/``Environment`` you are accessing the ``ObservableObject`` through is still `false`. The `.changed` property is only set `true` for step 3 (in a synchronous manner).

Moreover, in step 2, the evaluation could cause the ``ObservableObject`` to be replaced by a different ``ObservableObject``. In that case, the _unsolicited event_ would be cancelled and step 3 would be omitted.

### Representation on the Wire

You might think now: ok, but what about e.g. HTTP 1.x, which can only handle one request and one response? How is this even supposed to work?

The answer is: it might not and that is ok.

Not every exporter will be able to represent your endpoint exactly as you imagined, just because your ``Handler`` requires functionality that isn't supported by the exporter's middleware. In that case the exporter should print a warning on startup. However, the exporter should always try to get as close as possible to the desired functionality. E.g. a HTTP exporter could establish a session with the client to create the illusion of a connection, or it could allow the client to multiplex a series of message into the body of a single request. Finally, if all that doesn't help, you just need to switch to a different exporter/middleware that actually fulfills your requirements.

> Tip: Sometimes it can happen that the ``InterfaceExporter`` misinterprets how your ``Handler`` should be represented on the wire. If that happens, you can try to make it explicit using ``CommunicationalPattern``. Check out ``CommunicationalPatternMetadata`` for more information on how to do that.

If you want to read more about the reasoning and details of this, head over to the advanced section: <doc:CommunicationPattern>.

## Topics

### The Connection

- ``Connection``
- ``ConnectionState``
- ``Response``
- ``ConnectionEffect``

### Maintaining State

- ``State``
- ``DynamicProperty``

### Handling Unsolicited Events

- ``ObservableObject``
- ``Published``
- ``ObservedObject``
- ``EnvironmentObject``
- ``Environment``
- ``Delegate``
