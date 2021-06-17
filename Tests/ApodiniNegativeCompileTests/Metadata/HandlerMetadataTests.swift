//
//  File.swift
//  
//
//  Created by Andreas Bauer on 30.05.21.
//

import Apodini

private struct TestStruct: Handler {
    func handle() -> String {
        "Hello World!"
    }
    
    var metadata: Metadata {
        TestVoidHandlerMetadata()

        // error: Argument type 'AnyWebServiceMetadata' does not conform to expected type 'AnyHandlerMetadata'
        TestVoidWebServiceMetadata()

        // error: Argument type 'AnyComponentOnlyMetadata' does not conform to expected type 'AnyHandlerMetadata'
        TestVoidComponentOnlyMetadata()

        TestVoidComponentMetadata()

        // error: No exact matches in call to static method 'buildExpression'
        TestVoidContentMetadata()

        Block {
            TestVoidHandlerMetadata()
        }

        StandardHandlerMetadataBlock {
            TestVoidHandlerMetadata()

            // error: Argument type 'AnyWebServiceMetadata' does not conform to expected type 'AnyHandlerMetadata'
            TestVoidWebServiceMetadata()

            // error: Argument type 'AnyComponentOnlyMetadata' does not conform to expected type 'AnyHandlerMetadata'
            TestVoidComponentOnlyMetadata()

            TestVoidComponentMetadata()

            // error: No exact matches in call to static method 'buildExpression'
            TestVoidContentMetadata()
        }

        // error: Argument type 'AnyWebServiceMetadata' does not conform to expected type 'AnyHandlerMetadata'
        StandardWebServiceMetadataBlock {
            TestVoidWebServiceMetadata()
        }

        // error: Argument type 'AnyComponentOnlyMetadata' does not conform to expected type 'AnyHandlerMetadata'
        StandardComponentOnlyMetadataBlock {
            TestVoidComponentOnlyMetadata()
        }

        StandardComponentMetadataBlock {
            TestVoidComponentMetadata()
        }

        // error: No exact matches in call to static method 'buildExpression'
        StandardContentMetadataBlock {
            TestVoidContentMetadata()
        }
    }
}
