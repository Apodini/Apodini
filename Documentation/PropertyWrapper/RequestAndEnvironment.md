## `@Request` and `@Environment`

The `@Request` property wrapper is used to retrieve information identified by a key path that is obtained by a single incoming request. Global information about the web service is exposed by the `@Environment` property wrapper. 

Possible key paths for the `@Environment` property wrapper could include:
* `@Environment(\.database)` or the type `Database` to retrieve the current database.
* `@Environment(\.configuration)` or the type `Configuration` to get the current server configuration such as the IP address.

Possible key paths for the `@Request` property wrapper could include:
* `@Request(\.user)`: Returns the user that is associated with this request as injected by an authentication middleware, e.g., based on the authorization header of an HTTP request.
* `@Request(\.headers)` of the type `[HTTPHeaderKey: String]` to retrieve all headers assoicated with the current request.
* `@Request(\.uri)` of the type `URI` to retrieve URI of the request if applicable.
* `@Request(\.body)` of the type `Data` to retrieve the body if the current request.
* `@Request(\.httpType)` of the type HTTP protocol used.  

Middleware types and communication protocols that use lower level protocols such as WebSockets should expose the HTTP specific information of the `@Request` property wrappers from the initial handshare or provide feasable default values such as HTTP/2 for `@Request(\.httpType)`, an empty dictionary for `@Request(\.headers)`, or an empty URI for `@Request(\.uri)`.

```swift
struct Account: Model {
    @ID var id: UUID
    @Field var name: String
    @Field var balance: Int
    @Parent(/**/) var user: User

    // ...
}

/// Reads an Accound out of the request and saves the Account to a database
struct SaveAccountComponent: Component {
    @Parameter var account: Account
    @Environment(.\database) var database: Database 
    @Request(.\request) var user: ExampleUser 


    func handle() -> EventLoopFuture<Account> {
        // Sets the user to the authenticated user and saves the Account to the database (async operation).
        return Account.setUser(user).save(on: database)
    }
}
```
