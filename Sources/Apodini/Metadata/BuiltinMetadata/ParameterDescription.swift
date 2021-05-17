//
//  Created by Andreas Bauer on 17.05.21.
//

public struct ParameterDescriptionContextKey: OptionalContextKey {
    public typealias Value = String
}

public extension ComponentMetadataScope {
    typealias ParameterDescription = ParameterDescriptionMetadata
}

public struct ParameterDescriptionMetadata: ComponentMetadata {
    public typealias Key = ParameterDescriptionContextKey

    public let value: String

    public init(_ description: String) {
        self.value = description
    }
}

public extension ComponentMetadataScope {
    // THis can only be one particular AnyMetadata instance; if you want to make this multiple allowed
    // you have to make this a class und use subclassing!
    typealias ParameterDescriptions = CustomComponentMetadataGroup<ParameterDescriptionMetadata>
}

// TODO remove
struct TestHandler: Handler {
    func handle() throws -> String {
        "Hello World"
    }

    var metadata: Metadata {
        // TODO generic way to Group Metadata!
        Description("""
                    This is the description of the Endpoint
                    """)
        Collect {
            Description("asd")
        }
        /*
        ParameterDescriptions {
            ParameterDescription("asdjd")
            ParameterDescriptions {
                ParameterDescription("jhkadjkh")
            }
        }
        */
    }
}
