# Request-Response



## Overview

Request-Response is the simplest pattern. A simple hello world could look like this:

```swift
struct Greeter: Handler {
    @Parameter var name: String?

    func handle() -> String {
        "Hello, \(name ?? World)!"
    }
}
```

The above code does return `String` instead of an `Response<String>`. The following would result in the exact same behavior:

```swift
struct Greeter: Handler {
    @Parameter var name: String?

    func handle() -> Response<String> {
        .final("Hello, \(name ?? World)!")
    }
}
```

Of course for more advanced features (e.g. usage of database), the `handle` could also return an `EventLoopFuture<String>` or `EventLoopFuture<Response<String>>`.

