//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini

private struct TestStruct: Handler {
    func handle() -> String {
        "Hello World!"
    }
    
    var metadata: Metadata {
        TestVoidHandlerMetadata()

        // error: Argument type 'any AnyWebServiceMetadata' does not conform to expected type 'AnyHandlerMetadata'
        TestVoidWebServiceMetadata()

        // error: Argument type 'any AnyComponentOnlyMetadata' does not conform to expected type 'AnyHandlerMetadata'
        TestVoidComponentOnlyMetadata()

        TestVoidComponentMetadata()

        // error: No exact matches in call to static method 'buildExpression'
        TestVoidContentMetadata()

        Block {
            TestVoidHandlerMetadata()
        }

        StandardHandlerMetadataBlock {
            TestVoidHandlerMetadata()

            // error: Argument type 'any AnyWebServiceMetadata' does not conform to expected type 'AnyHandlerMetadata'
            TestVoidWebServiceMetadata()

            // error: Argument type 'any AnyComponentOnlyMetadata' does not conform to expected type 'AnyHandlerMetadata'
            TestVoidComponentOnlyMetadata()

            TestVoidComponentMetadata()

            // error: No exact matches in call to static method 'buildExpression'
            TestVoidContentMetadata()
        }

        // error: Argument type 'any AnyWebServiceMetadata' does not conform to expected type 'AnyHandlerMetadata'
        StandardWebServiceMetadataBlock {
            TestVoidWebServiceMetadata()
        }

        // error: Argument type 'any AnyComponentOnlyMetadata' does not conform to expected type 'AnyHandlerMetadata'
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
