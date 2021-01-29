![document type: documentation](https://apodini.github.io/resources/markdown-labels/document_type_documentation.svg)

# WebSocket Interface Exporter

The WebSocket exporter uses a custom **JSON** based protocol on top of WebSocket's **text** messages. This protocol can handle multiple concurrent connections on the same or different endpoints over one WebSocket channel. The Apodini service listens on `/apodini/websocket` for clients that want to communicate via the WebSocket Interface Exporter.

The protocol features five types of messages:

## `OpenContextMessage`

Opens a new context (wich is identified by a `<UUID>`) on a virtual endpoint (which is identified by the `<identifier>`). This message is sent by the client.
```json
{
    "context": "<UUID>",
    "endpoint": "<identifier>"
}
```

The `identifier` is based on the `Group` `Component`s:

Consider the following example service:

```swift
@PathParameter
var userId: Int

@ComponentBuilder
var testService: some Component {
    Text("Hello World!")
    Group("user", $userId) {
        UserHandler(userId: $userId)
        Group("stream") {
            StatefulUserHandler(userId: $userId)
        }
    }
} 
```
The `Text` would be available under `""`, `UserHandler` under `"user.:userId:"` and `StatefulUserHandler` would be identified by `"user.:userId:.stream"`.

## `CloseContextMessage`

Closes the context with the given `<UUID>`. This message-type must be sent by both, client and server. Sending this message means _'I am not going to send another message on this context'_.
```json
{
    "context": "<UUID>"
}
```

## `ClientMessage`

Sends input for a `Handler` to a specific `context`. The `parameters` must fit the input required by the `context`'s `endpoint` in it's current state. This message-type is only used by the client.
```json
{
    "context": "<UUID>",
    "parameters": {
        "<name1>": <value2>,
        "<name2>": <value2>,
        ...
    }
}
```

Take the following example:

```swift
struct UserHandler: Handler {
    @Parameter("id")
    var userId: Int
    @Parameter
    var name: String

    func handle() -> User {
        User(id: userId, name: name)
    }
}
```
The valid client message for this `Handler` would be:
```json
{
    "context": "<UUID>",
    "parameters": {
        "id": 5,
        "name": "Richard"
    }
}
```
Of course, you can use anything that is `Codable` as a parameter.

### Necessity and Nullability

Some `@Parameter`s are not required, e.g. for the following two, the client doesn't have to provide a value explicitly:
```swift
@Parameter var surname: String?
@Parameter var superPowers: [String] = []
```

Note that one could set `surname` to JSON's `null` explicitly, whereas that would result in an error for `superPowers`.

### Mutability

Let's take a look at this modified handler, which accepts multiple inputs and returns a new `User` instance for each of them:

```swift 
struct StatefulUserHandler: Handler {
    @Parameter("id", .mutability(.constant))
    var userId: Int
    @Parameter
    var name: String
    @Apodini.Environment(\.connection)
    var connection: Connection

    func handle() -> Apodini.Response<User> {
        if connection.state == .end {
            return .end
        } else {
            return .send(User(id: userId, name: name))
        }
    }
}
```

What is important here is the `.mutability(.constant)` option. With this option there, succeeding requests on the same context may not alter the `"id"`, i.e.:

This would be fine:
```json
{
    "context": "<UUID>",
    "parameters": {
        "id": 5,
        "name": "Richard Thompson"
    }
}
{
    "context": "<UUID>",
    "parameters": {
        "id": 5,
        "name": "Richard Fleming"
    }
}
```
But this would **not** be fine:
```json
{
    "context": "<UUID>",
    "parameters": {
        "id": 5,
        "name": "Richard Thompson"
    }
}
{
    "context": "<UUID>",
    "parameters": {
        "id": 15,
        "name": "Richard Fleming"
    }
}
```

Input values are cached, thus the client can omit values if it doesn't want to change them. The following would be a valid sequence:

```json
{
    "context": "<UUID>",
    "parameters": {
        "id": 5,
        "name": "Richard Thompson"
    }
}
{
    "context": "<UUID>",
    "parameters": {}
}
{
    "context": "<UUID>",
    "parameters": {
        "name": "Richard Fleming"
    }
}
{
    "context": "<UUID>",
    "parameters": {
        "id": 5
    }
}
```

## `ServiceMessage`

Sends output of a `Handler` to a speficic `context`. The `content`'s type is the same as the `Encodable` that is returned by the `Handler`'s `handle()` function. This message-type is only used by the server.

```json
{
    "context": "<UUID>",
    "content": <Content>
}
```

The `content` is encoded in JSON as you would expect:

```swift
struct User: Apodini.Content {
    let id: Int
    let name: String
}
```
```json
{
    "context": "<UUID>",
    "content": {
        "id": 5,
        "name": "Richard Thompson"
    }
}
```


## `ErrorMessage`

Sends an error-message to a speficic `context`. This message-type is only used by the server.

```json
{
    "context": "<UUID>",
    "error": "<Error_Message>"
}
```
If a `Handler` throws anything that is not an `ApodiniError`, this error is transformed to a generic `ApodiniError` with an `ErrorType.other`. The `Error`'s `localizedDescription` is reflected in the `ApodiniError`'s `description`.

Note that the error message of an `ApodiniError` changes when switching to production. The `description` is only exposed to the client in `DEBUG` mode.

### `WebSocketConnectionConsequence`

When throwing an `ApodiniError` you can specify what consequence this has for the associated `context` and WebSocket connection. There are three options: `.none`, `.closeContext` and `.closeChannel`. In any case the `ErrorMessage` is sent before the context is closed or the channel is closed.

```swift
struct UserHandler: Handler {
    @Throws(.badInput, "ID 0 is reserved.", .webSocketConnectionConsequence(.closeContext))
    var reservedIdError: ApodiniError

    @Parameter("id")
    var userId: Int
    @Parameter
    var name: String

    func handle() throws -> User {
        if userId == 0 {
            throw reservedIdError
        }

        return User(id: userId, name: name)
    }
}
```

### `WebSocketErrorCode`

This option is only relevant if the `WebSocketConnectionConsequence` is `.closeChannel`.

You can use any of the standard WebSocket error codes or even custom ones:

```swift
@Throws(.badInput, "ID 0 is reserved.", .webSocketConnectionConsequence(.closeChannel), .webSocketErrorCode(.unknown(12)))
    var reservedIdError: ApodiniError
```

### Defaults by `ErrorType`

|                    | `WebSocketConnectionConsequence` | `WebSocketErrorCode`           |
|--------------------|----------------------------------|--------------------------------|
| `.badInput`        | `.none`                          | `.dataInconsistentWithMessage` |
| `.notFound`        | `.none`                          | `.normalClosure`               |
| `.unauthenticated` | `.closeContext`                  | `.normalClosure`               |
| `.forbidden`       | `.closeChannel`                  | `.normalClosure`               |
| `.serverError`     | `.closeContext`                  | `.unexpectedServerError`       |
| `.notAvailable`    | `.closeContext`                  | `.normalClosure`               |
| `.other`           | `.closeContext`                  | `.normalClosure`               |
