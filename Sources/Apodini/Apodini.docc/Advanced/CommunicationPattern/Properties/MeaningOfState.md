# State

Description of State property wrapper and its usage in Apodini.

<!--
                  
This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT
             
-->

## Overview

`@State` allows for the developer to keep a state across multiple events, e.g. multiple messages that are part of the same connection. `@State` variables require a default value to be defined by the developer (except the `wrappedValue` is of an optional type). The `wrappedValue` has a setter.

## Lifetime

### Influence

The presence of `@State` properties on a `Handler` signalizes exporting the endpoint as a Client-Side Stream makes sense. If the exporter decides to do so the lifetime of the `Handler` has to be extended accordingly.

### Implementation-Details

#### Request-Response

If an exporter only supports the Request-Response pattern it should export all `@Parameter var x: T` as an array of type T. The arrays should be of same length for all parameters. The exporter then injects the elements for one index after another until either the evaluation of the `Handler` results in anything but `.nothing` or the end of the arrays is reached. The second case would result in an error.

A possible exception could be made for identifying parameters because representing those as an array could be difficult for some exporters and it seems very unlikely that one would like to stream identifiers.

#### Client-Side Stream

After the initial request to the endpoint the `Handler` is kept alive and waits for further incoming messages. The `Handler` is evaluated for each incoming message until the `Handler`'s logic comes to a state where it decides to return something else than `.nothing`. Afterwards the `Handler` can be destructed.

#### Service-Side Stream

The handling of the request should be similar to the one for Request-Response pattern.

#### Bidirectional Stream

The handling of incoming messages should be similar to the one for the Client-Side Stream pattern. The `Handler` is destructed when it evaluates to either `.end` or `.final(E)`.

## Control Flow

### Influence

`@State`s do not emit their own events.

### Implementation Details

The evaluation of `Handler` based on a certain event may never observe changes on an `@State` that are not caused by the same evaluation.
