# Retrieving Relationship Information

This proposal describes how relationship information can be generated from the DSL, introduces some concepts
to give hints for relationship retrieval and adds mechanisms for manually defined hints.

A potential REST interface exporter will use such relationship information to generate Hypermedia information.
Specifically it will generate hyperlinks which SHOULD be place in a designated `_links` section.
A REST exporter MAY also inline those links if it can ensure that no name collisions occur.  
This document proposes that [RFC 6570 URI Template](https://tools.ietf.org/html/rfc6570) SHOULD be used to encode those links.

The following chapters explain how such relationship information is generated.

## 1. Using the path "structure"

The path structure of the Webservice can be used to infer relationship information.  
For example the fact that the `/user/:userid/post` path is a subroute to `/user/:userid` path can be used to 
generate relationship information for every user, namely a relationship pointing to `user/{userid}/post`.

In general every endpoint will relate to **all** of its children/subroutes.

Giving an example: When a client sends a request for `/user/532` the a potential REST exporter will return the following:
```json
{
  "id": "532",
  "name": "Rudi",
  "lastname": "Raser",
  "email": "rudi@raser.de",
  "_links": {
    "self": "https://example.api/user/532",
    "post": "https://example.api/post"
  }
}
```

One of the core concepts of REST (with HATEOAS) is that a client does not need to know anything about the path structure.
Instead, just like a web browser, a client follows hyperlinks returned from the web service.  
This allows you to change the path structure of your REST service - keeping the same named links at the same places -
without breaking compatibility for your clients.

To support such scenarios there must be some sort of way to manually overwrite such relationship information.

## 2. Manually defining "structural" relationship information

This chapter imagines ways how a user could manually override or provide additional relationship information.

### 2.1. Overriding the relationship name

The above described inferring approach will use the string description of the `PathComponent` as the relationship name.
This may not fit everybody's needs.

Similar to how you can manually define a `@Parameter` name, you can also override a relationship name.
This proposal suggest a sort of `PathComponentModifier` (similar to `ComponentModifiers`).

Such a definition could then look like the following:
```swift
var content: some Component {
  Group("test".relationshipName("new-name")) {
    Handler()
  }
}
```

### 2.2. Adding new relationships

In order to support rearranging components, a user can also define its own relationships.
We introduce a `.relationship` modifier for `PathComponent`s, to which one would pass
a relationship name and `PathComponent`s describing the destination.  
The destination can of course also include `@PathParameters`.

Any manual definition of a relationship MUST always override a inferred relationship if the name collides.

Looking at the example below, a REST exporter would add the link `greeter` pointing to `/greeting/{userid}` on a 
response returned from `/user/:userId`. As the value of the `userId` `PathParameter` is known, it is replaced with
the actual value. `@PathParameter`s for which no predefined value can be inferred should be formatted according to
[RFC 6570](https://tools.ietf.org/html/rfc6570) (as well as potential query parameters of the destination). 

```swift
var content: some Component {
  Group("user", $userId.relationship("greeter", to: "greeting", $userId)) {
    Handler()
  }
  Group("greeting", $userId) {
    Greeter()
  }
}
```

### 2.3. Excluding relationships

It may also be a sensible decision for a user to hide a inferred relationship. To support that
a modifier can be introduce.

Even if a user supplies a `.relationshipName` modifier, the relationship will still be hidden when `.hideRelationshio` is used.

Considering the example below, a request to `/` will not include a relationship pointing to `/test`.

```swift
var content: some Component {
  Group("test".hideRelationship()) {
    Handler()
  }
}
```

## 3. Using type information

Checking the structure of the Webservice is already pretty powerful, but doesn't allow for relationships between handlers
which are on the same level or on different paths of the path component tree.  
This chapter highlights how we can nonetheless retrieve relationship information by looking at type information.

### 3.1 Looking at the return type of `handle()`

For this chapter we will look at the following example web service:

```swift
struct User: Identifiable {
  var id: String
  var name: String
  var lastname: String
  var email: String
}

struct TestService: WebService, Component {
  @PathParameter var userId: User.ID

  var content: some Component {
    Group("user", $postId) {
      UserHandler(userId: $userId)
    }
  }
}
```

It can be observed that the handle function of the `UserHandler` returns a `User` instance.
User conforms to the protocol `Identifiable`, so it is also known that every `User` instance is uniquely identified by the
`id` property.  
Furthermore the `UserHandler` is registered with a path parameter having the same `User.ID` type, meaning
we can assume that the `/user/:userId` route can be used to query a certain `User` instance
(meaning `:userId` translates to `User.id` property).

_Note: As the type of a `@PathParameter` is a `LosslessStringConvertible` it most certainly is either a 
`String` or an `Int`. Meaning checking if the type of the `User.id` property is equal to `User.ID` type might not be enough.
Thus it could be necessary for `@PathParemeter`s to specify the type: e.g. `@PathParameter(type: User.self)` where
the `type` argument must conform to the `Identifiable` protocol (or something similar as `Identifiable.ID` conforms 
to `Hashable` and we actually need `LosslessStringConvertible`)_

With that information a potential REST exporter could encode the following for a response of the `UserHandler`:

```json
{
  "id": "472",
  "name": "Andreas",
  "lastname": "Bauer",
  "email": "mail@example.org",
  "_links": {
    "self": "https://example.api/user/472"
  }
}
```

_Note: to be fair the `self` link can also be more easily retrieved by looking at what the client sent in its request.
However what we actually do is building a mapping from types to their respective `Handler`
which is needed for the following chapters._

### 3.2. `Handler`s which return an `Identifiable` but don't have a parameter

A special case to [3.1](#31-looking-at-the-return-type-of-handle) is, when we detect that a `Handler` returns a type
conforming to `Identifiable`, but doesn't have a `@PathParameter` which can be mapped to `.id` property.

This case is illustrated by the following example web service with the `MeUserHandler`:
```swift
struct TestService: WebService, Component {
  @PathParameter var userId: User.ID

  var content: some Component {
    Group("user", $postId) {
      UserHandler(userId: $userId)
      // could contain other routes giving more information for the given user, e.g. ./posts
    }
    Group("me") {
      MeUserHandler() // handle() returns `User`
    }
  }
}
```

In such a case, we can search the web service for a `Handler` which also returns `User`, but has a `@PathParameter`.
We could then find the `UserHandler` registered under `/user/:userId`.

A response returned from the `MeUserHandler` would then include a `self` relationship pointing to `/user/{userId}` 
(`userId` is known from the returned `User` instance). More specifically the response will include all relationships
which are also returned on a request to `user/:userId` (meaning links to potential subroutes).

**Open questions:**
* This approach heavily relies on the fact that `/me` returns the same type as `user/:userId`. It might be worth
  creating a explicit mechanism to define the `self` link in a case were `/me` would only return a subset of the properties
  of `User`.  
  This could be solved using the same mechanism as presented in [3.3](#33-defining-foreignkeys). 

### 3.3. Defining `ForeignKeys`

In this chapter we assume the existence of the example webservice from the previous chapter and adding a `/article`
handler.

```swift
var content: some Component {
  // ...
  Group("article", $articleId) {
    ArticleHandler(articleId: $articleId)
  }
}
```

The idea is, that every `Article` is written by a certain `User` (aka the author).
A potential REST API response should then include a link to the respective `User` resource.  
To be able to display such a relationship the user needs to provide that information to us.

A `Article` could then be defined like the following:
```swift
struct Article: IdentifiableWithForeignKeys {
  var id: String
  var heading: String
  var content: String

  var writtenBy: String

  static var foreignKeys: some ForeignKeys {
    ForeignKey<User>(name: "author", at: \.writtenBy)
  }
}
```

In this example the user indicates that the `.writtenBy` property holds the `.id` value of the Type `User` (which 
conforms to `Identifiable`) and additionally specifying that the relationship is called `author`.  
Similar to [3.2](#32-handlers-which-return-an-identifiable-but-dont-have-a-parameter) we can then look up 
the `Handler` which returns `User` instances and has a `@PathParameter` matched to the `.id` property.

For exporters using that relationship information (such as REST and GraphQL) the response should not contain
the `writtenBy` property but instead replace that by e.g. generating a appropriate entry in the `_links` section.  
Other exporters should ideally rename such fields by adding a `Id` suffix (e.g. `writtenById`). 

Below is a example response generated from a REST exporter for such a `ArticleHandler`:

```json
{
  "id": "3826",
  "heading": "Retrieving Relationship Information",
  "content": "...",
  "_links": {
    "author": "https://example.api/user/472",
    "self": "https://example.api/article/3826"
  }
}
```

## 4. Appendix

### 4.1. Example implementation of `var foreignKeys`

```swift
protocol ForeignKeys {
  associatedtype From
}

struct SomeForeignKey<From, To: Identifiable>: ForeignKeys {
  var name: String
  var type: To.Type
  var keyPath: KeyPath<From, To.ID>

  init(name: String, type: To.Type = To.self, at keyPath: KeyPath<From, To.ID>) {
    self.name = name
    self.type = type
    self.keyPath = keyPath
  }

  func foreignKeyValue(from: From) -> To.ID {
    from[keyPath: keyPath]
  }
}

protocol IdentifiableWithForeignKeys: Identifiable {
  typealias ForeignKey<To : Identifiable> = SomeForeignKey<Self, To>
  associatedtype Keys: ForeignKeys
  static var foreignKeys: Keys { get }
}

struct User: Identifiable {
  var id: String
  var name: String
  var lastname: String
  var email: String
}

struct Article: IdentifiableWithForeignKeys {
  var id: String
  var heading: String
  var content: String

  var writtenBy: String

  static var foreignKeys: some ForeignKeys {
    ForeignKey<User>(name: "author", at: \.writtenBy)
  }
}
```

### 4.2. Thought experiment: Reverse lookup for foreign keys

Given the example web service from [3.3](#33-defining-foreignkeys):
```swift
@PathParameter var userId: User.ID

var content: some Component {
  Group("user", $postId) {
    UserHandler(userId: $userId)
  }
  Group("article", $articleId) {
    ArticleHandler(articleId: $articleId)
  }
}
```

_Background: One could imagine that in the future a REST exporter could automatically generate
Pagination handlers for collection endpoints like `/user` and `/article`. At this point the pagination
generator could be extended to also incorporate some relationship functionality._

As describe in [3.3](#33-defining-foreignkeys) we can already add a relationship to the `.author` in every response
returned on the `/article/:articleId` endpoint.
What we currently can't do is the reverse lookup, retrieve all articles written by a certain `User`.
Right now the user would need to manually support that by supplying a appropriate `Handler`.  
Provided that the REST exporter is able to generate such a pagination route, this feature could be extended
to incorporate relationship information and add support for a `author` query parameter.  
A request to `/article?author={userId}` would then return a array of articles written by the specified `User`.
