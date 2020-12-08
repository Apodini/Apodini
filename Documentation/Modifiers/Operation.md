![document type: vision](https://apodini.github.io/resources/markdown-labels/document_type_vision.svg)

# Operation

This document describes what the `Operation` is and how interface exporters may deal with it.  
The `Operation` models all four basic CRUD operations. For every endpoint it is to be defined which operation is
represented by the given endpoint.

**The following operations are available:**
* `.automatic`: This is the default value for every endpoint.
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

**Inferring the http method on `.automatic`**

When `.automatic` is defined as the operation for an endpoint, the REST exporter (or any other http driven exporter)
SHOULD try to deterministically infer the resulting http method from the context (e.g. by the presence or absence of
`@Parameter`) or other wise default to `GET`.

Be aware that the `SharedSemanticModelBuilder` will consider `.automatic` to be a uniquely identifying operation.
As the the inferring process basically maps `.automatic` to any of the other `Operation` values,
`.automatic` itself CAN NOT be considered as a uniquely identifying value anymore.
It MUST be checked if the inferred http method created any conflict.
This can also impose the problem that changing any properties of a `Component` which are used
in the inferring process can lead to a different result for that calculation and thus creating a conflict.

### gRPC

As the `Operation` enum cannot be properly map to any feature of the technology itself (like HTTP methods can be
used for HTTP), the gRPC exporter SHOULD incorporate the operation into the naming of the procedure.  
As `.automatic` is the default value, meaning most likely the user hasn't specified any `.operation`, it should
be ignored and no changes should be done to the procedure name.


### GraphQL

The `.automatic` operation MAY be used (if possible) to infer if a `Component` is used to handle a query or a mutation.
If not possible it SHOULD default to `.read`.  
In any case the GraphQL should correctly match incoming request to their respective endpoints.
Simple queries should be handled by the `Component` with operation `.read` and mutations should be handled
by the appropriate `Component` with `.create`, `.update` or `.delete` operation.

### WebSocket

A WebSocket exporter MAY use this information as some sort of identifier.