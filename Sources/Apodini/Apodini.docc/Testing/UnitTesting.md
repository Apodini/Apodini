# Unit Testing in Apodini

Show how to create a typical test class for an Apodini web service.

## Overview

The following example shows you a typical test class used to cite unit test for an Apodini web service. We subclass from `XCTApdiniTest` or `XCTApodiniDatabaseTest` to already get access to an Apodini app instance in the unit tests and get convenience methods to access the database and add migrations `.addMigrations()` for `XCTApodiniDatabaseTest`.

The code snippets shown in this article are based on the Apodini example project in the <doc:DatabaseConnection>.

In line 8 we define a @PathParameter that showcases how you can define different parameters that can be passed to Handlers or Components in the test cases.

```swift
@testable import ExampleWebService
import Shared
import XCTApodini
import XCTApodiniDatabase
 
final class ContactHandlerTests: XCTApodiniDatabaseTest {
    @PathParameter var contactId: Contact.IDValue
     
    override func setUpWithError() throws {
        try super.setUpWithError()
         
        try addMigrations(
            ContactMigration(),
            ResidenceMigration()
        )
    }  
```

### XCTCheckHandler

`XCTCheckHandler(handler:,mocks:,):` can be used to test a single Handler.
The result builder expects one or more elements conforming to `Mock` like:
* `MockRequest` to send mock requests to a ``Handler``
* `MockObservedListener` to test observables, e.g. if they are triggered by requests
* `ExecuteClosure` to manually execute code between any other `Mock`s

A `MockRequest` can have different expectations or assertions defined that test the output of the mock request.
* In the first test we initialize the contact emma (Line 32) with attributes name and birthday and use the assertion closure that gets passed in the realist of the Handler invocation to test if the contact is displayed correctly using the `XCTAssertEqual()` function.
* `MockRequest` can also check based on using the build in equatable functionality of the response is the expected outcome. Using `MockRequest(expectation:)` you can direly pass in the expected result or a combination of the expected result, expected status code, and connection state after the `MockRequest`. (Line 49)

A `MockRequest` offers the possibility to pass parameters to the `Handler`.
* `UnnamedParameter(_:):` Defines an unnamed parameter (e.g. as part of the URL path) that is passed to the ``Handler`` and matched based on comparing the possible ``Parameter`` types and types of passed in `UnnammedParameter`.
* `NamedParameter(_:, value:):` Defines an named parameter that is passed to the ``Handler`` and matched based on comparing the possible ``Parameter`` names and types of passed in `NamedParameters.

```swift
func testCreateContact() throws {
    let emma = Contact(name: "Emma Stone", birthday: Date(timeIntervalSince1970: 594777600))
     
    try XCTCheckHandler(CreateContact()) {
        MockRequest(assertion: { (returnedContact: Contact) in
            XCTAssertEqual(returnedContact.name, emma.name)
            XCTAssertEqual(returnedContact.birthday, emma.birthday)
        }) {
            NamedParameter("contact", value: emma)
        }
    }
}

func testGetContacts() throws {
    let emma = Contact(name: "Emma Stone", birthday: Date(timeIntervalSince1970: 594777600))
    try emma.save(on: app.database).wait()
     
    try XCTCheckHandler(GetContacts()) {
        MockRequest(expectation: [emma])
```

### MockRequest Options

Apodini supports Web APIs that keep connections between different subsequent requests open, e.g. WebSockets and gRPC. Therefore the default behaviour is to keep the connections open between two dsubsequent `MockRequest`.

By default open connections reuse all available parameters from the previous request and reuse them for the next request. In contrast to request protocol specific exporters this can lead to unexpected behaviour in test cases that to not include a sophisticated logic to reduce parameters (UnnamedParameters are just aggregated, NamedParameter are overwritten if they have the same name).

Therefore `XCTApodini` includes options for each `MockRequest`:
* `subsequentRequest`: The default option. Reduces parameters: (`UnnamedParameters` are just aggregated, `NamedParameter` are overwritten if they have the same name)
* `doNotReduceRequest`: Does keep the connection context around (e.g. the connection stays open between requests) but does not reduce the parameters
* `doNotReuseConnection`: Creates a new connection context for the `MockRequest.

To simulate a REST request we do not reuse the connection context for subsequent requests here:

```swift
func testGreeeterWithParameter() throws {
    let emma = Contact(name: "Emma Stone", birthday: Date(timeIntervalSince1970: 594777600))
    try emma.save(on: app.database).wait()
    let ryan = Contact(name: "Ryan Reynolds", birthday: Date(timeIntervalSince1970: 214876800))
    try ryan.save(on: app.database).wait()
     
    try XCTCheckHandler(GetContact(contactId: $contactId)) {
        MockRequest(expectation: emma) {
            UnnamedParameter(emma.id)
        }
        MockRequest(expectation: ryan, options: .doNotReuseConnection) {
            UnnamedParameter(ryan.id)
        }
    }
}  
```

### XCTCheckComponent

You can also test ``Component``s using `XCTApodini`. Using `XCTCheckComponent` you pass in a complete ``Component`` and using `CheckHandler` you identify which ``Handler`` you want to use.

We currently envision three ways to identify ``Handler``:

* index: Identify a `Handler` using the index it is parsed when traversing the `Component` (Currently implemented)
* path: Identify a `Handler` using the path it is located at as defined when parsing the Apodini DSL (Currently not implemented)
* identifier: Identify a `Handler` using the unique identifier assigned by Apodini when parsing the Apodini DSL (Currently not implemented)
Exactly like `XCTCheckHandler` the `CheckHandler` result builder expects one or more Mocks to test the identified `Handler`.

```swift
func testGreeterComponentWithParameter() throws {
     try XCTCheckComponent(GreeterComponent()) {
         CheckHandler<Greeter>(index: 0) {
             MockRequest(expectation: Name(name: "Hello Paul 👋")) {
                 UnnamedParameter("Paul")
             }
         }
     }
 }
```


## Topics

### Testing

- <doc:NegativeCompileTest>
