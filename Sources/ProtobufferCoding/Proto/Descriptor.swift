//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

// swiftlint:disable identifier_name todo missing_docs


// NOTE:
// This file contains the data structures defined in https://github.com/protocolbuffers/protobuf/blob/master/src/google/protobuf/descriptor.proto,
// hand-translated into the corresponding Swift code.
// The important thing to keep in mind here is that the `descriptor.proto` currently (i.e. as of 2021-12-23) still uses proto2 syntax,
// which means that we have to be a bit careful when mapping optional/required fields into Swift properties.
// Essentially, as long as these properties are not initialised to the type's respective "zero" value,
// and as long as the field's don't define a default value other than what the Protobuffer{En|De}coder use, we should be good.
// An additional thing is that some of the field names were slightly changed to fit better into a Swift application
// (eg: pluralising the names of repeated fields, replacing snake_case identifiers with camelCase ones)
// This won't matter though, when creating and encoding a schema using these types, since the actual field names don't
// show up in the resulting proto data (only the field numbers do, of course).


private protocol _ProtoPackage_Google_Protobuf: ProtoTypeInPackage & Proto2Codable {}
extension _ProtoPackage_Google_Protobuf {
    public static var package: ProtobufPackageUnit {
        ProtobufPackageUnit(
            packageName: "google.protobuf",
            filename: "google/protobuf/descriptor.proto"
        )
    }
}


public struct FileDescriptorSet: Codable, ProtobufMessage, Hashable, _ProtoPackage_Google_Protobuf {
    public let files: [FileDescriptorProto]
    
    public init(files: [FileDescriptorProto]) {
        self.files = files
    }
}


public struct FileDescriptorProto: Codable, Hashable, ProtobufMessageWithCustomFieldMapping, _ProtoPackage_Google_Protobuf {
    /// file name, relative to root of source tree
    public let name: String
    /// e.g. "foo", "foo.bar", etc.
    public let package: String
    
    /// Names of files imported by this file.
    public var dependencies: [String]
    /// Indexes of the public imported files in the dependency list above.
    public let publicDependency: [Int32]
    /// Indexes of the weak imported files in the dependency list.
    /// For Google-internal migration only. Do not use.
    public let weakDependency: [Int32]
    
    /// All top-level definitions in this file.
    public let messageTypes: [DescriptorProto]
    public let enumTypes: [EnumDescriptorProto]
    public let services: [ServiceDescriptorProto]
    public let extensions: [FieldDescriptorProto]
    
    public let options: FileOptions?
    
    /// This field contains optional information about the original source code.
    /// You may safely remove this entire field without harming runtime
    /// functionality of the descriptors -- the information is needed only by
    /// development tools.
    public let sourceCodeInfo: SourceCodeInfo?
    
    /// The syntax of the proto file.
    /// The supported values are "proto2" and "proto3".
    public let syntax: String
    
    
    public enum CodingKeys: Int, ProtobufMessageCodingKeys {
        case name = 1
        case package = 2
        case dependencies = 3
        case publicDependency = 10
        case weakDependency = 11
        case messageTypes = 4
        case enumTypes = 5
        case services = 6
        case extensions = 7
        case options = 8
        case sourceCodeInfo = 9
        case syntax = 12
    }
    
    
    public init(
        name: String,
        package: String,
        dependencies: [String],
        publicDependency: [Int32],
        weakDependency: [Int32],
        messageTypes: [DescriptorProto],
        enumTypes: [EnumDescriptorProto],
        services: [ServiceDescriptorProto],
        extensions: [FieldDescriptorProto],
        options: FileOptions?,
        sourceCodeInfo: SourceCodeInfo?,
        syntax: String
    ) {
        precondition(!name.isEmpty)
        precondition(!package.isEmpty)
        precondition(!syntax.isEmpty)
        self.name = name
        self.package = package
        self.dependencies = dependencies
        self.publicDependency = publicDependency
        self.weakDependency = weakDependency
        self.messageTypes = messageTypes
        self.enumTypes = enumTypes
        self.services = services
        self.extensions = extensions
        self.options = options
        self.sourceCodeInfo = sourceCodeInfo
        self.syntax = syntax
    }
}


/// Describes a message type.
public struct DescriptorProto: Codable, Hashable, ProtobufMessageWithCustomFieldMapping, _ProtoPackage_Google_Protobuf {
    public var name: String
    
    public let fields: [FieldDescriptorProto]
    public let extensions: [FieldDescriptorProto]
    
    public var nestedTypes: [DescriptorProto]
    public var enumTypes: [EnumDescriptorProto]
    
    public struct ExtensionRange: Codable, ProtobufMessage, Hashable, _ProtoPackage_Google_Protobuf {
        /// Inclusive.
        public let start: Int32?
        /// Exclusive.
        public let end: Int32?
        public let options: ExtensionRangeOptions?
    }
    public let extensionRanges: [ExtensionRange]
    public let oneofDecls: [OneofDescriptorProto]
    public let options: MessageOptions?
    
    
    /// Range of reserved tag numbers. Reserved tag numbers may not be used by
    /// fields or extension ranges in the same message. Reserved ranges may
    /// not overlap.
    public struct ReservedRange: Codable, ProtobufMessage, Hashable, _ProtoPackage_Google_Protobuf {
        /// Inclusive.
        public let start: Int32?
        /// Exclusive.
        public let end: Int32?
    }
    public let reservedRanges: [ReservedRange]
    
    /// Reserved field names, which may not be used by fields in the same message.
    /// A given name may only be reserved once.
    public let reservedNames: [String]
    
    
    public enum CodingKeys: Int, ProtobufMessageCodingKeys {
        case name = 1
        case fields = 2
        case extensions = 6
        case nestedTypes = 3
        case enumTypes = 4
        case extensionRanges = 5
        case oneofDecls = 8
        case options = 7
        case reservedRanges = 9
        case reservedNames = 10
    }
}


public struct ExtensionRangeOptions: Codable, Hashable, ProtobufMessageWithCustomFieldMapping, _ProtoPackage_Google_Protobuf {
    /// The parser stores options it doesn't recognize here. See above.
    public let uninterpretedOptions: [UninterpretedOption]
    
//  // Clients can define custom options in extensions of this message. See above.
//  extensions 1000 to max;
    
    public enum CodingKeys: Int, ProtobufMessageCodingKeys {
        case uninterpretedOptions = 999
    }
}


/// Describes a field within a message.
public struct FieldDescriptorProto: Codable, Hashable, ProtobufMessageWithCustomFieldMapping, _ProtoPackage_Google_Protobuf {
    public enum FieldType: Int32, ProtobufEnum, _ProtoPackage_Google_Protobuf {
        /// 0 is reserved for errors.
        /// Order is weird for historical reasons.
        case TYPE_DOUBLE = 1
        case TYPE_FLOAT = 2
        /// Not ZigZag encoded.  Negative numbers take 10 bytes.  Use TYPE_SINT64 if
        /// negative values are likely.
        case TYPE_INT64 = 3
        case TYPE_UINT64 = 4
        /// Not ZigZag encoded.  Negative numbers take 10 bytes.  Use TYPE_SINT32 if
        /// negative values are likely.
        case TYPE_INT32 = 5
        case TYPE_FIXED64 = 6
        case TYPE_FIXED32 = 7
        case TYPE_BOOL = 8
        case TYPE_STRING = 9
        /// Tag-delimited aggregate.
        /// Group type is deprecated and not supported in proto3. However, Proto3
        /// implementations should still be able to parse the group wire format and
        /// treat group fields as unknown fields.
        case TYPE_GROUP = 10
        /// Length-delimited aggregate.
        case TYPE_MESSAGE = 11
        
        /// New in version 2.
        case TYPE_BYTES = 12
        case TYPE_UINT32 = 13
        case TYPE_ENUM = 14
        case TYPE_SFIXED32 = 15
        case TYPE_SFIXED64 = 16
        /// Uses ZigZag encoding.
        case TYPE_SINT32 = 17
        /// Uses ZigZag encoding.
        case TYPE_SINT64 = 18
    }
    
    public enum Label: Int32, ProtobufEnum, _ProtoPackage_Google_Protobuf {
        // 0 is reserved for errors
        case LABEL_OPTIONAL = 1
        case LABEL_REQUIRED = 2
        case LABEL_REPEATED = 3
    }
    
    
    public let name: String
    public let number: Int32
    public let label: Label?

    /// If type_name is set, this need not be set.  If both this and type_name
    /// are set, this must be one of TYPE_ENUM, TYPE_MESSAGE or TYPE_GROUP.
    public let type: FieldType?

    /// For message and enum types, this is the name of the type.  If the name
    /// starts with a '.', it is fully-qualified.  Otherwise, C++-like scoping
    /// rules are used to find the type (i.e. first the nested types within this
    /// message are searched, then within the parent, on up to the root
    /// namespace).
    public let typename: String?

    /// For extensions, this is the name of the type being extended.  It is
    /// resolved in the same manner as type_name.
    public let extendee: String?

    /// For numeric types, contains the original text representation of the value.
    /// For booleans, "true" or "false".
    /// For strings, contains the default text contents (not escaped in any way).
    /// For bytes, contains the C escaped value.  All bytes >= 128 are escaped.
    /// TODO(kenton):  Base-64 encode?
    public let defaultValue: String?
    
    /// If set, gives the index of a oneof in the containing type's oneof_decl
    /// list.  This field is a member of that oneof.
    public let oneofIndex: Int32?
    
    /// JSON name of this field. The value is set by protocol compiler. If the
    /// user has set a "json_name" option on this field, that option's value
    /// will be used. Otherwise, it's deduced from the field's name by converting
    /// it to camelCase.
    public let jsonName: String?
    
    public let options: FieldOptions?
    
  /// If true, this is a proto3 "optional". When a proto3 field is optional, it
  /// tracks presence regardless of field type.
  ///
  /// When `proto3_optional` is true, this field must be belong to a oneof to
  /// signal to old proto3 clients that presence is tracked for this field. This
  /// oneof is known as a "synthetic" oneof, and this field must be its sole
  /// member (each proto3 optional field gets its own synthetic oneof). Synthetic
  /// oneofs exist in the descriptor only, and do not generate any API. Synthetic
  /// oneofs must be ordered after all "real" oneofs.
  ///
  /// For message fields, `proto3_optional` doesn't create any semantic change,
  /// since non-repeated message fields always track presence. However it still
  /// indicates the semantic detail of whether the user wrote "optional" or not.
  /// This can be useful for round-tripping the .proto file. For consistency we
  /// give message fields a synthetic oneof also, even though it is not required
  /// to track presence. This is especially important because the parser can't
  /// tell if a field is a message or an enum, so it must always create a
  /// synthetic oneof.
  ///
  /// Proto2 optional fields do not set this flag, because they already indicate
  /// optional with `LABEL_OPTIONAL`.
    public let proto3Optional: Bool
    
    
    public enum CodingKeys: Int, ProtobufMessageCodingKeys {
        case name = 1
        case number = 3
        case label = 4
        case type = 5
        case typename = 6
        case extendee = 2
        case defaultValue = 7
        case oneofIndex = 9
        case jsonName = 10
        case options = 8
        case proto3Optional = 17
    }
}


/// Describes a oneof.
public struct OneofDescriptorProto: Codable, ProtobufMessage, Hashable, _ProtoPackage_Google_Protobuf {
    public let name: String?
    public let options: OneofOptions?
}


/// Describes an enum type.
public struct EnumDescriptorProto: Codable, Hashable, ProtobufMessageWithCustomFieldMapping, _ProtoPackage_Google_Protobuf {
    public var name: String
    public let values: [EnumValueDescriptorProto]
    public let options: EnumOptions?
    
    /// Range of reserved numeric values. Reserved values may not be used by
    /// entries in the same enum. Reserved ranges may not overlap.
    ///
    /// Note that this is distinct from DescriptorProto.ReservedRange in that it
    /// is inclusive such that it can appropriately represent the entire int32
    /// domain.
    public struct EnumReservedRange: Codable, ProtobufMessage, Hashable, _ProtoPackage_Google_Protobuf {
        /// Inclusive.
        public let start: Int32?
        /// Inclusive.
        public let end: Int32?
    }
    
    /// Range of reserved numeric values. Reserved numeric values may not be used
    /// by enum values in the same enum declaration. Reserved ranges may not
    /// overlap.
    public let reservedRanges: [EnumReservedRange]
    
    /// Reserved enum value names, which may not be reused. A given name may only
    /// be reserved once.
    public let reservedNames: [String]
    
    
    public enum CodingKeys: Int, ProtobufMessageCodingKeys {
        case name = 1
        case values = 2
        case options = 3
        case reservedRanges = 4
        case reservedNames = 5
    }
}


/// Describes a value within an enum.
public struct EnumValueDescriptorProto: Codable, ProtobufMessage, Hashable, _ProtoPackage_Google_Protobuf {
    public let name: String
    public let number: Int32
    public let options: EnumValueOptions?
}


/// Describes a service.
public struct ServiceDescriptorProto: Codable, ProtobufMessage, Hashable, _ProtoPackage_Google_Protobuf {
    public let name: String
    public let methods: [MethodDescriptorProto]
    public let options: ServiceOptions?
    
    public init(name: String, methods: [MethodDescriptorProto], options: ServiceOptions?) {
        self.name = name
        self.methods = methods
        self.options = options
    }
}


/// Describes a method of a service.
public struct MethodDescriptorProto: Codable, Hashable, ProtobufMessageWithCustomFieldMapping, _ProtoPackage_Google_Protobuf {
    public let name: String
    
    /// Input and output type names.  These are resolved in the same way as
    /// FieldDescriptorProto.type_name, but must refer to a message type.
    public let inputType: String
    public let outputType: String

    public let options: MethodOptions?

    /// Identifies if client streams multiple client messages
    public let clientStreaming: Bool
    /// Identifies if server streams multiple server messages
    public let serverStreaming: Bool

    public var sourceCodeComments: [String] = []
    
    public enum CodingKeys: Int, ProtobufMessageCodingKeys {
        case name = 1
        case inputType = 2
        case outputType = 3
        case options = 4
        case clientStreaming = 5
        case serverStreaming = 6
        case sourceCodeComments = 7
    }
    
    
    public init(
        name: String,
        inputType: String,
        outputType: String,
        options: MethodOptions?,
        clientStreaming: Bool,
        serverStreaming: Bool,
        sourceCodeComments: [String] = []
    ) {
        self.name = name
        self.inputType = inputType
        self.outputType = outputType
        self.options = options
        self.clientStreaming = clientStreaming
        self.serverStreaming = serverStreaming
        self.sourceCodeComments = sourceCodeComments
    }

    public func formatCommentSection(commentStyle: String = "//") -> String? {
        guard !sourceCodeComments.isEmpty else {
            return nil
        }

        return sourceCodeComments
            .map { "\(commentStyle) \($0)" }
            .joined(separator: "\n")
            .appending("\n")
    }
}


// MARK: Options

public struct FileOptions: Codable, Hashable, ProtobufMessageWithCustomFieldMapping, _ProtoPackage_Google_Protobuf {
//    // Sets the Java package where classes generated from this .proto will be
//    // placed.  By default, the proto package is used, but this is often
//    // inappropriate because proto packages do not normally start with backwards
//    // domain names.
//    optional string java_package = 1;
//
//    // If set, all the classes from the .proto file are wrapped in a single
//    // outer class with the given name.  This applies to both Proto1
//    // (equivalent to the old "--one_java_file" option) and Proto2 (where
//    // a .proto always translates to a single class, but you may want to
//    // explicitly choose the class name).
//    optional string java_outer_classname = 8;
//
//    // If set true, then the Java code generator will generate a separate .java
//    // file for each top-level message, enum, and service defined in the .proto
//    // file.  Thus, these types will *not* be nested inside the outer class
//    // named by java_outer_classname.  However, the outer class will still be
//    // generated to contain the file's getDescriptor() method as well as any
//    // top-level extensions defined in the file.
//    optional bool java_multiple_files = 10 [default = false];
//
//    // This option does nothing.
//    optional bool java_generate_equals_and_hash = 20 [deprecated=true];
//
//    // If set true, then the Java2 code generator will generate code that
//    // throws an exception whenever an attempt is made to assign a non-UTF-8
//    // byte sequence to a string field.
//    // Message reflection will do the same.
//    // However, an extension field still accepts non-UTF-8 byte sequences.
//    // This option has no effect on when used with the lite runtime.
//    optional bool java_string_check_utf8 = 27 [default = false];
    
    /// Generated classes can be optimized for speed or code size.
    public enum OptimizeMode: Int32, ProtobufEnum, _ProtoPackage_Google_Protobuf {
        case SPEED = 1          // Generate complete code for parsing, serialization, etc.
        case CODE_SIZE = 2     // Use ReflectionOps to implement these methods.
        case LITE_RUNTIME = 3  // Generate code using MessageLite and the lite runtime.
    }
//    optional OptimizeMode optimize_for = 9 [default = SPEED];
    public let optimizeMode: OptimizeMode?

//    // Sets the Go package where structs generated from this .proto will be
//    // placed. If omitted, the Go package will be derived from the following:
//    //   - The basename of the package import path, if provided.
//    //   - Otherwise, the package statement in the .proto file, if present.
//    //   - Otherwise, the basename of the .proto file, without extension.
//    optional string go_package = 11;


//    // Should generic services be generated in each language?  "Generic" services
//    // are not specific to any particular RPC system.  They are generated by the
//    // main code generators in each language (without additional plugins).
//    // Generic services were the only kind of service generation supported by
//    // early versions of google.protobuf.
//    //
//    // Generic services are now considered deprecated in favor of using plugins
//    // that generate code specific to your particular RPC system.  Therefore,
//    // these default to false.  Old code which depends on generic services should
//    // explicitly set them to true.
//    optional bool cc_generic_services = 16 [default = false];
//    optional bool java_generic_services = 17 [default = false];
//    optional bool py_generic_services = 18 [default = false];
//    optional bool php_generic_services = 42 [default = false];

    /// Is this file deprecated?
    /// Depending on the target platform, this can emit Deprecated annotations
    /// for everything in the file, or it will be completely ignored; in the very
    /// least, this is a formalization for deprecating files.
    public let deprecated: Bool

//    // Enables the use of arenas for the proto messages in this file. This applies
//    // only to generated classes for C++.
//    optional bool cc_enable_arenas = 31 [default = true];


//    // Sets the objective c class prefix which is prepended to all objective c
//    // generated classes from this .proto. There is no default.
//    optional string objc_class_prefix = 36;
//
//    // Namespace for generated classes; defaults to the package.
//    optional string csharp_namespace = 37;
//
//    // By default Swift generators will take the proto package and CamelCase it
//    // replacing '.' with underscore and use that to prefix the types/symbols
//    // defined. When this options is provided, they will use this value instead
//    // to prefix the types/symbols defined.
//    optional string swift_prefix = 39;
//
//    // Sets the php class prefix which is prepended to all php generated classes
//    // from this .proto. Default is empty.
//    optional string php_class_prefix = 40;
//
//    // Use this option to change the namespace of php generated classes. Default
//    // is empty. When this option is empty, the package name will be used for
//    // determining the namespace.
//    optional string php_namespace = 41;
//
//    // Use this option to change the namespace of php generated metadata classes.
//    // Default is empty. When this option is empty, the proto file name will be
//    // used for determining the namespace.
//    optional string php_metadata_namespace = 44;
//
//    // Use this option to change the package of ruby generated classes. Default
//    // is empty. When this option is not set, the package name will be used for
//    // determining the ruby package.
//    optional string ruby_package = 45;


    /// The parser stores options it doesn't recognize here.
    /// See the documentation for the "Options" section above.
    public let uninterpretedOptions: [UninterpretedOption]

//    // Clients can define custom options in extensions of this message.
//    // See the documentation for the "Options" section above.
//    extensions 1000 to max;
    
    public static var reservedFields: Set<ProtoReservedField> {
        [.index(38)]
    }
    
    public enum CodingKeys: Int, ProtobufMessageCodingKeys {
        case optimizeMode = 9
        case deprecated = 23
        case uninterpretedOptions = 999
    }
}


public struct MessageOptions: Codable, Hashable, ProtobufMessageWithCustomFieldMapping, _ProtoPackage_Google_Protobuf {
//    // Set true to use the old proto1 MessageSet wire format for extensions.
//    // This is provided for backwards-compatibility with the MessageSet wire
//    // format.  You should not use this for any other reason:  It's less
//    // efficient, has fewer features, and is more complicated.
//    //
//    // The message must be defined exactly as follows:
//    //   message Foo {
//    //     option message_set_wire_format = true;
//    //     extensions 4 to max;
//    //   }
//    // Note that the message cannot have any defined fields; MessageSets only
//    // have extensions.
//    //
//    // All extensions of your type must be singular messages; e.g. they cannot
//    // be int32s, enums, or repeated messages.
//    //
//    // Because this is an option, the above two restrictions are not enforced by
//    // the protocol compiler.
//    optional bool message_set_wire_format = 1 [default = false];
    
//    // Disables the generation of the standard "descriptor()" accessor, which can
//    // conflict with a field of the same name.  This is meant to make migration
//    // from proto1 easier; new code should avoid fields named "descriptor".
//    optional bool no_standard_descriptor_accessor = 2 [default = false];
    
    /// Is this message deprecated?
    /// Depending on the target platform, this can emit Deprecated annotations
    /// for the message, or it will be completely ignored; in the very least,
    /// this is a formalization for deprecating messages.
    public var deprecated: Bool
    
    /// Whether the message is an automatically generated map entry type for the
    /// maps field.
    ///
    /// For maps fields:
    ///
    ///     map<KeyType, ValueType> map_field = 1;
    ///
    /// The parsed descriptor looks like:
    ///
    ///     message MapFieldEntry {
    ///         option map_entry = true;
    ///         optional KeyType key = 1;
    ///         optional ValueType value = 2;
    ///     }
    ///     repeated MapFieldEntry map_field = 1;
    ///
    /// Implementations may choose not to generate the map_entry=true message, but
    /// use a native map in the target language to hold the keys and values.
    /// The reflection APIs in such implementations still need to work as
    /// if the field is a repeated message field.
    ///
    /// NOTE: Do not set the option in .proto files. Always use the maps syntax
    /// instead. The option should only be implicitly set by the proto compiler
    /// parser.
    public var mapEntry: Bool
    
//    reserved 8;  // javalite_serializable
//    reserved 9;  // javanano_as_lite
    
    
//    // The parser stores options it doesn't recognize here. See above.
//    repeated UninterpretedOption uninterpreted_option = 999;

//    // Clients can define custom options in extensions of this message. See above.
//    extensions 1000 to max;
    
    public enum CodingKeys: Int, ProtobufMessageCodingKeys {
        case deprecated = 3
        case mapEntry = 7
    }
    
    public static var reservedFields: Set<ProtoReservedField> {
        [.index(4), .index(5), .index(6), .index(8), .index(9)]
    }
}


public struct FieldOptions: Codable, Hashable, ProtobufMessageWithCustomFieldMapping, _ProtoPackage_Google_Protobuf {
    public enum CType: Int32, ProtobufEnum, _ProtoPackage_Google_Protobuf {
        /// Default mode.
        case STRING = 0
        case CORD = 1
        case STRING_PIECE = 2
    }
    /// The ctype option instructs the C++ code generator to use a different
    /// representation of the field than it normally would.  See the specific
    /// options below.  This option is not yet implemented in the open source
    /// release -- sorry, we'll try to include it in a future version!
    public let ctype: CType? //    optional CType ctype = 1 [default = STRING];

    /// The packed option can be enabled for repeated primitive fields to enable
    /// a more efficient representation on the wire. Rather than repeatedly
    /// writing the tag and type for each element, the entire array is encoded as
    /// a single length-delimited blob. In proto3, only explicit setting it to
    /// false will avoid using packed encoding.
    public let packed: Bool //    optional bool packed = 2;

    // The jstype option determines the JavaScript type used for values of the
    // field.  The option is permitted only for 64 bit integral and fixed types
    // (int64, uint64, sint64, fixed64, sfixed64).  A field with jstype JS_STRING
    // is represented as JavaScript string, which avoids loss of precision that
    // can happen when a large value is converted to a floating point JavaScript.
    // Specifying JS_NUMBER for the jstype causes the generated JavaScript code to
    // use the JavaScript "number" type.  The behavior of the default option
    // JS_NORMAL is implementation dependent.
    //
    // This option is an enum to permit additional types to be added, e.g.
    // goog.math.Integer.
//    optional JSType jstype = 6 [default = JS_NORMAL];
    public let jsType: JSType?
    public enum JSType: Int32, ProtobufEnum, _ProtoPackage_Google_Protobuf {
        // Use the default type.
        case JS_NORMAL = 0
        
        // Use JavaScript strings.
        case JS_STRING = 1
        
        // Use JavaScript numbers.
        case JS_NUMBER = 2
    }

    /// Should this field be parsed lazily?  Lazy applies only to message-type
    /// fields.  It means that when the outer message is initially parsed, the
    /// inner message's contents will not be parsed but instead stored in encoded
    /// form.  The inner message will actually be parsed when it is first accessed.
    ///
    /// This is only a hint.  Implementations are free to choose whether to use
    /// eager or lazy parsing regardless of the value of this option.  However,
    /// setting this option true suggests that the protocol author believes that
    /// using lazy parsing on this field is worth the additional bookkeeping
    /// overhead typically needed to implement it.
    ///
    /// This option does not affect the public interface of any generated code;
    /// all method signatures remain the same.  Furthermore, thread-safety of the
    /// interface is not affected by this option; const methods remain safe to
    /// call from multiple threads concurrently, while non-const methods continue
    /// to require exclusive access.
    ///
    ///
    /// Note that implementations may choose not to check required fields within
    /// a lazy sub-message.  That is, calling IsInitialized() on the outer message
    /// may return true even if the inner message has missing required fields.
    /// This is necessary because otherwise the inner message would have to be
    /// parsed in order to perform the check, defeating the purpose of lazy
    /// parsing.  An implementation which chooses not to check required fields
    /// must be consistent about it.  That is, for any particular sub-message, the
    /// implementation must either *always* check its required fields, or *never*
    /// check its required fields, regardless of whether or not the message has
    /// been parsed.
    public let `lazy`: Bool

    /// Is this field deprecated?
    /// Depending on the target platform, this can emit Deprecated annotations
    /// for accessors, or it will be completely ignored; in the very least, this
    /// is a formalization for deprecating fields.
    public let deprecated: Bool

    /// For Google-internal migration only. Do not use.
    public let `weak`: Bool


    /// The parser stores options it doesn't recognize here. See above.
    public let uninterpretedOptions: [UninterpretedOption]

//    // Clients can define custom options in extensions of this message. See above.
//    extensions 1000 to max;
//
//    reserved 4;  // removed jtype
    
    
    public enum CodingKeys: Int, ProtobufMessageCodingKeys {
        case ctype = 1
        case packed = 2
        case jsType = 6
        case `lazy` = 5
        case deprecated = 3
        case `weak` = 10
        case uninterpretedOptions = 999
    }
    
    public static var reservedFields: Set<ProtoReservedField> {
        [.index(4)]
    }
}


public struct OneofOptions: Codable, Hashable, ProtobufMessageWithCustomFieldMapping, _ProtoPackage_Google_Protobuf {
    /// The parser stores options it doesn't recognize here. See above.
    public let uninterpretedOptions: [UninterpretedOption]
    
//  // Clients can define custom options in extensions of this message. See above.
//  extensions 1000 to max;
    
    public enum CodingKeys: Int, ProtobufMessageCodingKeys {
        case uninterpretedOptions = 999
    }
}


public struct EnumOptions: Codable, Hashable, ProtobufMessageWithCustomFieldMapping, _ProtoPackage_Google_Protobuf {
    /// Set this option to true to allow mapping different tag names to the same value.
    public let allowAlias: Bool

    /// Is this enum deprecated?
    /// Depending on the target platform, this can emit Deprecated annotations
    /// for the enum, or it will be completely ignored; in the very least, this
    /// is a formalization for deprecating enums.
    public let deprecated: Bool

//    reserved 5;  // javanano_as_lite

    /// The parser stores options it doesn't recognize here. See above.
    public let uninterpretedOptions: [UninterpretedOption]

//    // Clients can define custom options in extensions of this message. See above.
//    extensions 1000 to max;
    
    public enum CodingKeys: Int, ProtobufMessageCodingKeys {
        case allowAlias = 2
        case deprecated = 3
        case uninterpretedOptions = 999
    }
    
    public static var reservedFields: Set<ProtoReservedField> {
        [.index(5)]
    }
}


public struct EnumValueOptions: Codable, Hashable, ProtobufMessageWithCustomFieldMapping, _ProtoPackage_Google_Protobuf {
    /// Is this enum value deprecated?
    /// Depending on the target platform, this can emit Deprecated annotations
    /// for the enum value, or it will be completely ignored; in the very least,
    /// this is a formalization for deprecating enum values.
    public let deprecated: Bool

    /// The parser stores options it doesn't recognize here. See above.
    public let uninterpretedOptions: [UninterpretedOption]

//  // Clients can define custom options in extensions of this message. See above.
//  extensions 1000 to max;
    
    public enum CodingKeys: Int, ProtobufMessageCodingKeys {
        case deprecated = 1
        case uninterpretedOptions = 999
    }
}


public struct ServiceOptions: Codable, Hashable, ProtobufMessageWithCustomFieldMapping, _ProtoPackage_Google_Protobuf {
    // Note:  Field numbers 1 through 32 are reserved for Google's internal RPC
    //   framework.  We apologize for hoarding these numbers to ourselves, but
    //   we were already using them long before we decided to release Protocol
    //   Buffers.

    /// Is this service deprecated?
    /// Depending on the target platform, this can emit Deprecated annotations
    /// for the service, or it will be completely ignored; in the very least,
    /// this is a formalization for deprecating services.
    public let deprecated: Bool

    /// The parser stores options it doesn't recognize here. See above.
    public let uninterpretedOptions: [UninterpretedOption]

//    // Clients can define custom options in extensions of this message. See above.
//    extensions 1000 to max;
    
    public enum CodingKeys: Int, ProtobufMessageCodingKeys {
        case deprecated = 33
        case uninterpretedOptions = 999
    }
}


public struct MethodOptions: Codable, Hashable, ProtobufMessageWithCustomFieldMapping, _ProtoPackage_Google_Protobuf {
    // Note:  Field numbers 1 through 32 are reserved for Google's internal RPC
    //   framework.  We apologize for hoarding these numbers to ourselves, but
    //   we were already using them long before we decided to release Protocol
    //   Buffers.

    /// Is this method deprecated?
    /// Depending on the target platform, this can emit Deprecated annotations
    /// for the method, or it will be completely ignored; in the very least,
    /// this is a formalization for deprecating methods.
    public let deprecated: Bool

    /// Is this method side-effect-free (or safe in HTTP parlance), or idempotent,
    /// or neither? HTTP based RPC implementation may choose GET verb for safe
    /// methods, and PUT verb for idempotent methods instead of the default POST.
    public enum IdempotencyLevel: Int32, ProtobufEnum, _ProtoPackage_Google_Protobuf {
        case IDEMPOTENCY_UNKNOWN = 0
        /// implies idempotent
        case NO_SIDE_EFFECTS = 1
        /// idempotent, but may have side effects
        case IDEMPOTENT = 2
    }
//    optional IdempotencyLevel idempotency_level = 34 [default = IDEMPOTENCY_UNKNOWN];
    public let idempotencyLevel: IdempotencyLevel?

    /// The parser stores options it doesn't recognize here. See above.
    public let uninterpretedOptions: [UninterpretedOption]

//    // Clients can define custom options in extensions of this message. See above.
//    extensions 1000 to max;
    
    
    public enum CodingKeys: Int, ProtobufMessageCodingKeys {
        case deprecated = 33
        case idempotencyLevel = 34
        case uninterpretedOptions = 999
    }
}


/// A message representing a option the parser does not recognize. This only
/// appears in options protos created by the compiler::Parser class.
/// DescriptorPool resolves these when building Descriptor objects. Therefore,
/// options protos in descriptor objects (e.g. returned by Descriptor::options(),
/// or produced by Descriptor::CopyTo()) will never have UninterpretedOptions
/// in them.
public struct UninterpretedOption: Codable, Hashable, ProtobufMessageWithCustomFieldMapping, _ProtoPackage_Google_Protobuf {
    /// The name of the uninterpreted option.  Each string represents a segment in
    /// a dot-separated name.  is_extension is true iff a segment represents an
    /// extension (denoted with parentheses in options specs in .proto files).
    /// E.g.,{ ["foo", false], ["bar.baz", true], ["qux", false] } represents
    /// "foo.(bar.baz).qux".
    public struct NamePart: Codable, ProtobufMessage, Hashable, _ProtoPackage_Google_Protobuf {
        public let namePart: String
        public let isExtension: Bool
    }
    
    public let names: [NamePart]

    /// The value of the uninterpreted option, in whatever type the tokenizer
    /// identified it as during parsing. Exactly one of these should be set.
    public let identifierValue: String?
    public let positiveIntValue: UInt64?
    public let negativeIntValue: Int64?
    public let doubleValue: Double?
    public let stringValue: [UInt8]
    public let aggregateValue: String?
    
    
    public enum CodingKeys: Int, ProtobufMessageCodingKeys {
        case names = 2
        case identifierValue = 3
        case positiveIntValue = 4
        case negativeIntValue = 5
        case doubleValue = 6
        case stringValue = 7
        case aggregateValue = 8
    }
}


// ===================================================================
// Optional source code info

/// Encapsulates information about the original source file from which a
/// FileDescriptorProto was generated.
public struct SourceCodeInfo: Codable, Hashable, ProtobufMessage, _ProtoPackage_Google_Protobuf {
    /// A Location identifies a piece of source code in a .proto file which
    /// corresponds to a particular definition.  This information is intended
    /// to be useful to IDEs, code indexers, documentation generators, and similar
    /// tools.
    ///
    /// For example, say we have a file like:
    ///   message Foo {
    ///     optional string foo = 1;
    ///   }
    /// Let's look at just the field definition:
    ///   optional string foo = 1;
    ///   ^       ^^     ^^  ^  ^^^
    ///   a       bc     de  f  ghi
    /// We have the following locations:
    ///   span   path               represents
    ///   [a,i)  [ 4, 0, 2, 0 ]     The whole field definition.
    ///   [a,b)  [ 4, 0, 2, 0, 4 ]  The label (optional).
    ///   [c,d)  [ 4, 0, 2, 0, 5 ]  The type (string).
    ///   [e,f)  [ 4, 0, 2, 0, 1 ]  The name (foo).
    ///   [g,h)  [ 4, 0, 2, 0, 3 ]  The number (1).
    ///
    /// Notes:
    /// - A location may refer to a repeated field itself (i.e. not to any
    ///   particular index within it).  This is used whenever a set of elements are
    ///   logically enclosed in a single code segment.  For example, an entire
    ///   extend block (possibly containing multiple extension definitions) will
    ///   have an outer location whose path refers to the "extensions" repeated
    ///   field without an index.
    /// - Multiple locations may have the same path.  This happens when a single
    ///   logical declaration is spread out across multiple places.  The most
    ///   obvious example is the "extend" block again -- there may be multiple
    ///   extend blocks in the same scope, each of which will have the same path.
    /// - A location's span is not always a subset of its parent's span.  For
    ///   example, the "extendee" of an extension declaration appears at the
    ///   beginning of the "extend" block and is shared by all extensions within
    ///   the block.
    /// - Just because a location's span is a subset of some other location's span
    ///   does not mean that it is a descendant.  For example, a "group" defines
    ///   both a type and a field in a single declaration.  Thus, the locations
    ///   corresponding to the type and field and their components will overlap.
    /// - Code which tries to interpret locations should probably be designed to
    ///   ignore those that it doesn't understand, as more types of locations could
    ///   be recorded in the future.
    public let locations: [Location]
    
    public struct Location: Codable, Hashable, ProtobufMessageWithCustomFieldMapping, _ProtoPackage_Google_Protobuf {
        /// Identifies which part of the FileDescriptorProto was defined at this
        /// location.
        ///
        /// Each element is a field number or an index.  They form a path from
        /// the root FileDescriptorProto to the place where the definition.  For
        /// example, this path:
        ///   [ 4, 3, 2, 7, 1 ]
        /// refers to:
        ///
        ///     file.message_type(3)  // 4, 3
        ///         .field(7)         // 2, 7
        ///         .name()           // 1
        /// This is because FileDescriptorProto.message_type has field number 4:
        ///   repeated DescriptorProto message_type = 4;
        /// and DescriptorProto.field has field number 2:
        ///   repeated FieldDescriptorProto field = 2;
        /// and FieldDescriptorProto.name has field number 1:
        ///   optional string name = 1;
        ///
        /// Thus, the above path gives the location of a field name.  If we removed
        /// the last element:
        ///   [ 4, 3, 2, 7 ]
        /// this path refers to the whole field declaration (from the beginning
        /// of the label to the terminating semicolon).
        public let path: [Int32]

        /// Always has exactly three or four elements: start line, start column,
        /// end line (optional, otherwise assumed same as start line), end column.
        /// These are packed into a single field for efficiency.  Note that line
        /// and column numbers are zero-based -- typically you will want to add
        /// 1 to each before displaying to a user.
        public let span: [Int32]

        /// If this SourceCodeInfo represents a complete declaration, these are any
        /// comments appearing before and after the declaration which appear to be
        /// attached to the declaration.
        ///
        /// A series of line comments appearing on consecutive lines, with no other
        /// tokens appearing on those lines, will be treated as a single comment.
        ///
        /// leading_detached_comments will keep paragraphs of comments that appear
        /// before (but not connected to) the current element. Each paragraph,
        /// separated by empty lines, will be one comment element in the repeated
        /// field.
        ///
        /// Only the comment content is provided; comment markers (e.g. //) are
        /// stripped out.  For block comments, leading whitespace and an asterisk
        /// will be stripped from the beginning of each line other than the first.
        /// Newlines are included in the output.
        ///
        /// Examples:
        ///
        ///     optional int32 foo = 1;  // Comment attached to foo.
        ///     // Comment attached to bar.
        ///     optional int32 bar = 2;
        ///
        ///     optional string baz = 3;
        ///     // Comment attached to baz.
        ///     // Another line attached to baz.
        ///
        ///     // Comment attached to qux.
        ///     //
        ///     // Another line attached to qux.
        ///     optional double qux = 4;
        ///
        ///     // Detached comment for corge. This is not leading or trailing comments
        ///     // to qux or corge because there are blank lines separating it from
        ///     // both.
        ///
        ///     // Detached comment for corge paragraph 2.
        ///
        ///     optional string corge = 5;
        ///     /* Block comment attached
        ///      * to corge.  Leading asterisks
        ///      * will be removed. */
        ///     /* Block comment attached to
        ///      * grault. */
        ///     optional int32 grault = 6;
        ///
        ///   // ignored detached comments.
        public let leadingComments: String?
        public let trailingComments: String?
        public let leadingDetachedComments: [String]
        
        public enum CodingKeys: Int, ProtobufMessageCodingKeys {
            case path = 1
            case span = 2
            case leadingComments = 3
            case trailingComments = 4
            case leadingDetachedComments = 6
        }
    }
}


/// Describes the relationship between generated code and its original source
/// file. A GeneratedCodeInfo message is associated with only one generated
/// source file, but may contain references to different source .proto files.
public struct GeneratedCodeInfo: Codable, ProtobufMessage, Hashable, _ProtoPackage_Google_Protobuf {
    /// An Annotation connects some span of text in generated code to an element
    /// of its generating .proto file.
    public let annotatioins: [Annotation]
    public struct Annotation: Codable, ProtobufMessage, Hashable, _ProtoPackage_Google_Protobuf {
        /// Identifies the element in the original source .proto file. This field
        /// is formatted the same as SourceCodeInfo.Location.path.
        public let path: [Int32]

        /// Identifies the filesystem path to the original source .proto.
        public let sourceFile: String?

        /// Identifies the starting offset in bytes in the generated code
        /// that relates to the identified object.
        public let begin: Int32?

        /// Identifies the ending offset in bytes in the generated code that
        /// relates to the identified offset. The end offset should be one past
        /// the last relevant byte (so the length of the text = end - begin).
        public let end: Int32?
    }
}
