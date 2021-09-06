# ``Operation``

<!--
                  
This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT
             
-->

@Metadata {
    @DocumentationExtension(mergeBehavior: append)
}

## Overview
 
The `Operation` models all four basic CRUD operations. For every endpoint it is to be defined which operation is
represented by the given endpoint.

**The following operations are available:**
* `.create`: The given endpoint describes some sort of **creation** operation.
* `.read`: The given endpoint describes some sort of **reading** operation.
* `.update`: The given endpoint describes some sort of **update** operation.
* `.delete`: The given endpoint describes some sort of **delete** operation.

The operation for a `Component` can be set using the `.operation` modifier. This modification is only valid
for the specified component (e.g. defining it on a `Group` won't affect members of that group).

Every `Component` is uniquely identified by its path and its `Operation` (e.g. There can be multiple components under
the same path `/user` but describing different operations).

## How exporters should treat those values

### REST

**The four CRUD operations map to their http method equivalent:**
* `.create`: maps to `POST`
* `.read`: maps to`GET`
* `.update`: maps to `PUT`
* `.delete`: maps to `DELETE`

### gRPC

As the `Operation` enum cannot be properly map to any feature of the technology itself (like HTTP methods can be
used for HTTP), the gRPC exporter SHOULD incorporate the operation into the naming of the procedure.  


### GraphQL

In any case the GraphQL should correctly match incoming request to their respective endpoints.
Simple queries should be handled by the `Component` with operation `.read` and mutations should be handled
by the appropriate `Component` with `.create`, `.update` or `.delete` operation.

### WebSocket

A WebSocket exporter MAY use this information as some sort of identifier.

## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->
