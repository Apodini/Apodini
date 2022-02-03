# Pattern Implementation

Implemented communication patterns.

<!--
                  
This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT
             
-->

## Overview

Apodini enables the developer to describe a functionality for a certain endpoint using ``Handler``s. Apodini's exporters try to export as much as possible of this functionality using the toolset provided by their respective protocols. In certain cases the protocol does not support all of the functionality described in the ``Handler``. That is when Apodini has to downgrade the functionality to fit the protocol's restrictions. Apodini automatically tries to find an alternative representation in the incompatible protocol so that the exported service does not become dysfunctional. Of course, the developer should be able to choose the exported pattern for each exporter individually if the automatic choice does not meet their needs.

In the rare cases where that is not possible, the developer may decide to hide this incompatible endpoint from a specific exporter on a ``Component``-level and provide an alternative implementation that is compatible with a more basic communication pattern.

## Support

In the future, the developer should be able to use Apodini's tooling without thinking about communication patterns and what protocols they want to support and still end up with fully functional services from all exporters.

Currently, most exporters do not support all communication patterns:

|           | Request-Response | Client-Side Stream | Service-Side Stream | Bidirectional Stream |
|-----------|------------------|--------------------|---------------------|----------------------|
| RESTful   | ✅                | ❌                  | ❌                   | ❌                    |
| gRPC      | ✅                | ✅                  | ❌                   | ❌                    |
| WebSocket | ✅                | ✅                  | ✅                   | ✅                    |
| GraphQL   | ✅                | ❌                  | ❌                   | ❌                    |


The following sections detail how different communication patterns can be implemented using the tools described in the previous chapter.

## Topics

### Pattern Implementation

- <doc:RequestResponse>
- <doc:ClientSideStream>
- <doc:ServiceSideStream>
- <doc:BidirectionalStream>
