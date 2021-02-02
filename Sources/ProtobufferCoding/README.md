#  Protobuffer encoding  and decoding

## Type mapping
To be able to (de)serialize Swift data into Protobuffer encoded messages, we need to define a mapping between Swift types and Protobuffer types.

### `ProtoDecoder`: Protobuffer types to Swift types (based on `protoc` compiler)
The Protobuffer compiler `protoc` serves as a reference on how to map Protobuffer types to Swift types:

| Wire type | Protobuffer type | Encoding | Swift type |
|-|-|-|-|
| 0 (VarInt) | int32 / int64    | **not** ZigZag    | Int / Int32 / Int64     |
| 0 (VarInt) | uint32 / uint64  | **not** ZigZag    | UInt / UInt32 / UInt64   |
| *0 (VarInt)* | *sint32 / sint64* | *ZigZag*       | *Int32 / Int64*   |
| 0 (VarInt) | bool             |                   | Bool              |
| 0 (VarInt) | enum             | **not** ZigZag    | Int32             |
|||||
| 1 (64-bit) | fixed64          | **not** ZigZag    | UInt64            |
| 1 (64-bit) | sfixed64         | **not** ZigZag    | Int64             |
| 1 (64-bit) | double           | **not** ZigZag    | Double            |
|||||
| 2 (length-delimited) | string | UTF8              | String            |
| 2 (length-delimited) | bytes  |                   | Data              |
| 2 (length-delimited) | embedded message |         | Codable struct    |
|||||
| 5 (32-bit) | fixed32          | **not** ZigZag    | UInt32            |
| 5 (32-bit) | sfixed32         | **not** ZigZag    | Int32             |
| 5 (32-bit) | float            | **not** ZigZag    | Float             |

Groups (with wire types 3 and 4) are not supported by Apodini, because they are deprecated from the Protobuffer standard.

**Problem:** As you can see, the Protobuffer type `int32` **is not** ZigZag encoded, and is mapped to the Swift type `Int32`. However, the Protobuffer type `sint32` **is** ZigZag encoded, and is also mapped to the Swift type `Int32` (the same holds for `int64` and `sint64`). Thus, when decoding without a `.proto` file, based on the Swift type we cannot tell whether ZigZag decoding should be applied or not.

**Current solution:** The Protobuffer types `sint32` and `sint64` are not supported by the `ProtoDecoder`. You can still transfer negative integer numbers using the Protobuffer types `int32` and `int64`. As a consequence, you cannot profit from the supposed better efficiency of ZigZag encoding.

### `ProtoEncoder`: Swift types to Protobuffer types

| Swift type | Encoding | Protobuffer type | Wire type |
|-|-|-|-|
| Int     | **not** ZigZag    | int32 / Int64 (depending on system architecture) | 0 (VarInt) |
| Int32     | **not** ZigZag    | int32     | 0 (VarInt) |
| Int64     | **not** ZigZag    | int64     | 0 (VarInt) |
| UInt      | **not** ZigZag    | uint32 / uint64 (depending on system architecture) | 0 (VarInt) |
| UInt32    | **not** ZigZag    | uint32    | 0 (VarInt) |
| UInt64    | **not** ZigZag    | uint32    | 0 (VarInt) |
| Bool      |                   | bool      | 0 (VarInt) |
| Enum      |  | not supported yet | |
| Data      |                   | bytes     | 2 (length-delimited) |
| String    | UTF8              | string    | 2 (length-delimited) |
| Embedded codable struct |     | embedded message | 2 (length-delimited) |
| Double    | **not** ZigZag    | double    | 1 (64-bit) |
| Float     | **not** ZigZag    | float     | 5 (32-bit) |

**Note:** The `ProtoEncoder` will never output `fixed32`, `sfixed32`, `fixed64` or `sfixed64` encoded values. Thus, we recommend to also not use those types on the client-side (even though the `ProtoDecoder` is able to decode them).

The Swift types `Int8`, `Int16`, `UInt8`, and `UInt16` do not have a Protobuffer equivalent and are thus not supported.

### `repeated` fields
Currently `repeated` fields are supported for all available scalar types (`int32`, `int64`, `uint32`, `uint64`, `float`, `double`, and `bool`). As of `proto3` version, all of these types are encoded packed by default. The decoder only supports decoding packed repeated fields. The encoder will also output packed encoding.

Further, `repeated` fields are also supported for the types `string` and `bytes`, both of which are not encoded packed.

**Note:** `repeated` is currently not supported for composite types / messages.


## Defining Protobuffer messages using Swift structs
The `ProtoEncoder` and `ProtoDecoder` are designed to work with Swift structs that implement the `Codable` protocol. Thus, defining a Protobuffer message is very straightforward:
```swift
struct ExampleMessage: Codable {
    var content: String
    var number: Int32
}
```
With such a struct, the first property `content` will be assigned the Protobuffer field tag 1, the second property `number` will be assigned the Protobuffer field tag 2, and so on.

Using the `CodingKey` enum, you can also explicitly define the respective field tags of the Protobuffer message:
```swift
struct ExampleMessage: Codable {
    var content: String
    var number: Int32

    enum CodingKeys: Int, CodingKey {
        case content = 1
        case number = 2
    }
}
```

In case you want to use `String` as raw values for the `CodingKey` enum (e.g. to be able to sensibly use the same struct also with `JSONEncoder`s), Apodini will derive a default integer value for each enum case. Again, the first enum case will get the field tag 1, the second one will get field tag 2, and so on.

Further, you can also specify your own custom integer values for your `String` based `CodingKey` enumeration, by implementing the `ProtoCodingKey` protocol and its `var protoRawValue: Int`:

```swift
struct ExampleMessage: Codable {
    var content: String
    var number: Int32

    enum CodingKeys: Int, CodingKey, ProtoCodingKey {
        case content = "content"
        case number = "number"

        var protoRawValue: Int {
            switch key {
            case CodingKeys.content:
                return 1
            case CodingKeys.number:
                return 2
            }
        }
    }
}
```

The `ProtoEncoder` and `ProtoDecoder` will always first try to extract an `Int` raw value from given `CodingKey`s. If that is not possible, they will try to access the explicitly provided `protoRawValue` property. If this property is not available, they will rely on the default integer value, which is derived by simply iterating over all the enumeration cases (as described above).