# Communication Pattern

Communicational patterns and their usage in different client-service protocols.

<!--
                  
This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT
             
-->

## Overview

All types of client-service communication consist of _messages_. A message can be sent from client to service (_client-message_) or from service to client (_service-message_). 

### Schema Notation

#### Semantics:
* `()`: unsolicited event (an event that is not captured by client-service communication protocols)
* `[x]`: array of `x`
* `x -> y`: `x` triggers `y`
* `x -?> y`: `x` can trigger `y`

#### Example:

The schema `() -?> client-message -> service-message` translates to: "An unsolicited event **may** trigger the client to send a message to the service, which then **always** results in the service sending a message back to the client."

### Distinct Patterns in Client-Service Communication

All client-service communication protocols/frameworks (exported by Apodini) each support a subset of the following classes of client-service communication:

 1. **Request-Response**: A single request is answered by a single response  
 schema: `() -?> client-message -> service-message`  
 supported by: HTTP1.x, HTTP2.0, GraphQL, gRPC, WebSocket
 2. **Client-Side Stream**: Multiple requests by a client that are terminated by a single response from the web service
 schema: `() -?> [client-message] -> service-message`
 supported by: gRPC, WebSocket
 3. **Service-Side Stream**: A single response is answered by multiple responses that are terminated by the web service  
 schema: `() -?> client-message -> [service-message]`  
 supported by: HTTP2.0, GraphQL (subscriptions), gRPC, WebSocket
 4. **Bidirectional Stream**: An open communication channel where both parties can send messages at any time. The connection is terminated by either the client or web service
 schema: `() -?> client-message <?-?> service-message <?- ()`
 supported by: gRPC, WebSocket
 5. **Unsolicited Message**: An unsolicited message that is sent to an _unspecified addressee_ from the web service based on some event
 schema: `() -?> service-message`
 supported by: APNS

## Apodini's Paradigm

 In general Apodini aims to provide a declarative DSL that is **by default agnostic** of the exported communication protocols. However, the DSL also allows for **customization** of the service's behavior for single exporters in a **protocol-specific** way. This also applies to Apodini's API for handling all of the above communication-patterns.

The problem is that certain classes of client-service communication are not supported by all communication protocols. The developer can create an endpoint that makes use of a more advanced pattern but exporters responsible for a protocol that does not fully support this pattern cannot export the exact functionality as described by the developer.

Apodini seeks to solve this problem by **not committing to a specific pattern** in the DSL with each pattern having its own API, but instead **providing tools to the developer that may have downgraded functionality based on the exporter**, the associated protocol and its restrictions.

This implies two necessities for Apodini's API in order to stay protocol-agnostic by default:

Firstly, Apodini's API must not explicitly mark an endpoint as an instance of one of our five communicational patterns. 

Secondly, Apodini's API must be flexible enough so that the **decision, which pattern is used** to implement a specific endpoint, can be **made by each exporter on its own**.

In order to achieve this goal, Apodini utilizes a SwiftUI-like approach allowing the developer to express their endpoint's logic using a _function of a state_ paradigm. In order to support this paradigm, Apodini provides different _property wrappers_ which are dynamically managed by Apodini. Those property wrappers influence the control-flow, i.e. when the developer's logic is executed and when messages are sent. These "tools" make up Apodini's API for implementing an endpoint's logic. However, the resulting behavior may differ from exporter to exporter.

## Further Reading

The chapter <doc:Tooling> describes our vision on how Apodini's API for implementing an endpoint's logic will look like. This also includes information on how certain exporters might interact with different property wrappers.

Chapter <doc:PatternImplementation> details how the tools presented in chapter 2. can be used to implement the communicational patterns listed in this document.

For the implementation of the Unsolicited Message pattern for push notification services refer to <doc:PushNotifications>.


## Topics

### Tooling

- <doc:Tooling>



### Pattern Implementation

- <doc:PatternImplementation>
- <doc:RequestResponse>
- <doc:ClientSideStream>
- <doc:ServiceSideStream>
- <doc:BidirectionalStream>


