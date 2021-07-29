# Database Connection

Connect Apodini project to a database system.

<!--
                  
This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT
             
-->

## Overview

Apodini uses [Fluent](https://docs.vapor.codes/4.0/fluent/overview/) provide easy access to the database, including the creation of model types which represent data structures. These models are then used to perform create, read, update, and delete operations instead of writing raw queries.
ApodiniDatabase currently supports the default drivers supported by [Fluent](https://docs.vapor.codes/4.0/fluent/overview/): [PostgreSQL](https://www.postgresql.org), [SQLite](https://www.sqlite.org), [MySQL](https://www.mysql.com), and [MongoDB](https://www.mongodb.com).

## Configuration

### Add Target Dependency

Add `ApodiniDatabase` dependency to the target in `Package.swift` file.

```swift
targets: [
    .target(
        name: "Your Target",
        dependencies: [
            // ...
            .product(name: "ApodiniDatabase", package: "Apodini")
        ])
]‚
```

### Add Database Configuration

Add `DatabaseConfiguration` to the `configuration` property of the `WebService`.

```swift
struct ExampleWebService: WebService {
    var content: some Component {
        // ...
    }
    
    var configuration: Configuration {
        
        // ...

        DatabaseConfiguration(.sqlite(.file("./apodini-database.sqlite")))
            
            // ...
    }
}
```
Apodini also supports another drivers: `.defaultMongoDB`, `.defaultPostgreSQL`, `.postgreSQL`, `.defaultMySQL`, and `.mySQL`.

### Add Fluent Migrations

Apodini provides `.addMigrations(_:)` function to add one or more `Migrations`.

```swift
struct ExampleWebService: WebService {
    var content: some Component {
        ContactComponent()
    }
    
    var configuration: Configuration {
        
        // ...

        DatabaseConfiguration(.sqlite(.file("./apodini-database.sqlite")))
            .addMigrations(ExampleMigration())
    }
}
```

The `Migration` should conform to Fluent [Migration](https://docs.vapor.codes/4.0/fluent/migration/) protocol.

It is required to prepare your object models beforehand. They should conform to Fluent [Model](https://docs.vapor.codes/4.0/fluent/model/).

> Important: Each object model should also conform to ``Content``.

### Define Components

You can use ``Component`` to define the route based on the input parameter as follows:

```swift
struct ContactComponent: Component {
    @PathParameter
    var contactId: Contact.IDValue
    
    
    var content: some Component {
        Group("contacts") {
            
            CreateContact()
                .operation(.create)
            
            GetContacts()
            
            Group($contactId) {
                
                GetContact(contactId: $contactId)
                
                UpdateContact(contactId: $contactId)
                    .operation(.update)
                
                DeleteContact(contactId: $contactId)
                    .operation(.delete)
            }
        }
    }
}
```

In this case, the `contactId` can be passed as a path in the URL request
```
http://localhost:8080/v1/contacts/<contactId>
```
For every endpoint it is to be defined which ``operation`` is represented by the given endpoint.

> Tip: Learn more advance relationship retrieval: <doc:RetrieveRelationship>


### Query Example

The following shows a `Handler` to update a `Contact` instance in the database.

```swift
import ApodiniDatabase
import Fluent
import Foundation
import NIO

struct UpdateContact: Handler {

    /// SQLite Database as an environmental object
    @Environment(\.database)
    var database: Database
    
    /// Identifier that specifies a unique `Contact`
    @Parameter
    var runId: Contact.IDValue
    
    /// The mediator that is passed in the HTTP body and containts the updated values of the `Contact`
    @Parameter(.http(.body))
    var runMediator: ContactMediator
    
    /// Error that is thrown if the specified `Contact` doens't exists in the database
    @Throws(.notFound, reason: "The Contact could not be found")
    var notFound: ApodiniError
    
    /**
    Update a specific `Contact`
    - Returns: The updated `Contact` object
    */
    func handle() throws -> EventLoopFuture<Contact> {
        Contact
            /// Find specific `Contact` object
            .find(contactId, on: database)
            /// Throw error if `Contact` couldn't be found
            .unwrap(orError: notFound)
            .flatMap { contact in

                /// Apply the mediator to the fetched `Contact` from the database
                contactMediator.apply(to: contact)
                
                /// Update the `Contact` in the database and return the updated object
                return run
                    .update(on: database)
                    .transform(to: contact)
            }
    }
}
```
The `runMediator` uses a ``Parameter`` with an HTTP mode option `.body` to parse the value from HTTP body.

> Important: The function calls within `handle()` uses the SwiftNIO asynchronous operations with [EventLoopFuture](https://apple.github.io/swift-nio/docs/current/NIO/Classes/EventLoopFuture.html) and Fluent's [Query API](https://docs.vapor.codes/4.0/fluent/query/)

> Note: ``ApodiniError`` provides a structure to throw an error from `Handlers` and recieves treatment from the interface exporters.



## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->
