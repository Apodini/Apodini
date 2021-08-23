//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini

private struct TestWebService: WebService {
    var content: some Component {
        Text("Hello World!")
    }

    var metadata: Metadata {
        // error: Argument type 'AnyHandlerMetadata' does not conform to expected type 'AnyWebServiceMetadata'
        TestVoidHandlerMetadata()

        TestVoidWebServiceMetadata()

        TestVoidComponentMetadata()

        // error: No exact matches in call to static method 'buildExpression'
        TestVoidContentMetadata()

        Block {
            TestVoidWebServiceMetadata()
        }

        StandardWebServiceMetadataBlock {
            // error: Argument type 'AnyHandlerMetadata' does not conform to expected type 'AnyWebServiceMetadata'
            TestVoidHandlerMetadata()

            TestVoidWebServiceMetadata()

            TestVoidComponentMetadata()

            // error: No exact matches in call to static method 'buildExpression'
            TestVoidContentMetadata()
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

private struct TestWebService2: WebService {
    var content: some Component {
        Text("Hello World!")
    }

    var metadata: Metadata {
        TestVoidWebServiceMetadata()

        // error: Argument type 'AnyComponentOnlyMetadata' does not conform to expected type 'AnyWebServiceMetadata'
        TestVoidComponentOnlyMetadata()

        // error: Argument type 'AnyHandlerMetadata' does not conform to expected type 'AnyWebServiceMetadata'
        StandardHandlerMetadataBlock {
            TestVoidHandlerMetadata()
        }

        TestVoidWebServiceMetadata()

        StandardWebServiceMetadataBlock {
            TestVoidWebServiceMetadata()

            // error: Argument type 'AnyComponentOnlyMetadata' does not conform to expected type 'AnyWebServiceMetadata'
            TestVoidComponentOnlyMetadata()
        }

        // error: Argument type 'AnyComponentOnlyMetadata' does not conform to expected type 'AnyWebServiceMetadata'
        StandardComponentOnlyMetadataBlock {
            TestVoidComponentOnlyMetadata()
        }
    }
}
