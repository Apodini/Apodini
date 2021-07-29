# Environment

Description of Environment property wrapper and its usage in Apodini.

<!--
                  
This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT
             
-->

## Overview

The `@Environment` property wrapper provides different functionality depending on the `wrappedValue`. For more detail on how the `wrappedValue` is provided to the environment and what values are provided by the Apodini framework refer to **RequestAndEnivornment**.

## Connection

Apodini provides a `Connection` through the environment. This object can be accessed using `@Environment(\.connection)`. The `Connection` provides useful protocol-agnostic information about the current state of the communication.

The most important property of `Connection` is `state: ConnectionState`. This state can be `.open` or `.end`, where `.end` signalizes that the protocol expects the connection to be closed now. The `Handler` may be destructed after the next evaluation. It should return `.end` or `.final(E)` now. A change to `Connection.state` is handled the same as a change to `@Parameter`, i.e. **one** client-message that includes updates to `@Parameter`s and `Connection.state` results in **one** evaluation; **one** client-message that does not update any `@Parameter`s but does update `Connection.state` also results in **one** evaluation of the `Handler`.

The `Connection` could provide a `start: Date` so the service could e.g. close connections with an timeout error.

## NotificationCenter

The `NotificationCenter` is used to send push notifications to APNS and FCM. It can be used in a `Handler`` using `@Environment(\.notificationCenter)`. Refer to <doc:PushNotifications> for more information.

## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->
