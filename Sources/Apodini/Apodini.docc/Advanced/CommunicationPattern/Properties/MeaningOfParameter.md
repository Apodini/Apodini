# Parameter

Specifying input for endpoints with Parameter property wrapper in Apodini.

<!--
                  
This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT
             
-->

## Overview

The property wrapper `@Parameter` is the central interface for the developer to specify what input is required for their endpoint. `@Parameter` properties are injected with a value when a message from the client arrives and before a ``Handler`` is evaluated. The `@Parameter`'s `wrappedValue` has no setter.

For information on how a specific exporter represents an `@Parameter` in its respective protocol and how this can be customized, refer to ``Parameter``.   


## Lifetime

### Influence

The presence of `@Parameter` properties on a `Handler` has no influence on the ``Handler``'s lifetime, i.e. how long it is kept in memory after it has been initially accessed.

### Implementation-Details

If the exporter allows for multiple messages to arrive on one instance of this endpoint (connection), then subsequent messages may override the values held in `@Parameter` properties. The contents of an `@Parameter` may never be reset (except for when the `Handler` is destructed). In case the evaluation of a `Handler` is triggered by another event than an incoming message, the `@Parameter` still holds the latest injected value.

## Control Flow

### Influence

`@Parameter`s do not emit their own events. The Apodini framework makes sure the arrival of a new incoming message is treated as an atomic event. That is:

1. `Handler`s are not evaluated once for each `@Parameter` that is injected with a value, but once for each incoming message.
2. Other events causing the `Handler` to be evaluated cannot be processed in parallel.
3. Another `Property`'s public members cannot change while a `Handler` is evaluated except by the `Handler`'s `handle` function.

### Implementation-Details

#### Request-Response

Once a request arrives for an endpoint, all `@Parameter`s living on the initial `Handler` are injected using the exporter's decoder. Afterwards the `Handler` is evaluated.

#### Client-Side Stream

Once a request arrives for an endpoint, all `@Parameter`s living on the initial `Handler` are injected using the exporter's decoder. Afterwards the `Handler` is evaluated. This process is repeated for every incoming message until the `Handler` is destructed.

Once a value was injected into an `@Parameter` it is never deleted. However, the exporter can allow subsequent messages to overwrite an `@Parameter`. If the injection of one `@Parameter` results in an error and therefore the `Handler` is not evaluated, the previous successfully injected `@Parameter`s have to be reset to their respective state before the erroneous client-message arrived.

#### Service-Side Stream

Refer to the Request-Response pattern.

#### Bidirectional Stream

Refer to the Client-Side Stream pattern.

#### Future Aspects

If in future, `Handler`s can delegate work to other `Handler`s, the process of evaluating the `Handler`` becomes more complicated:
If the `Handler` evaluates to another `Handler`, the process of injecting `@Parameter`s and then evaluating the `Handler` is recursively repeated with the child-`Handler` until the `Handler` evaluates to a `handle()` function. Then this `handle()` function is executed and the `Handler` is destructed.
