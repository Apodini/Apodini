//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini

private struct TestContent: Content {
    static var metadata: Metadata {
        // error: No exact matches in call to static method 'buildExpression'
        TestVoidHandlerMetadata()

        // error: No exact matches in call to static method 'buildExpression'
        TestVoidWebServiceMetadata()

        // error: No exact matches in call to static method 'buildExpression'
        TestVoidComponentOnlyMetadata()

        // error: No exact matches in call to static method 'buildExpression'
        TestVoidComponentMetadata()

        TestVoidContentMetadata()

        Block {
            TestVoidContentMetadata()
        }

        // error: No exact matches in call to static method 'buildExpression'
        StandardHandlerMetadataBlock {
            TestVoidHandlerMetadata()
        }

        // error: No exact matches in call to static method 'buildExpression'
        StandardWebServiceMetadataBlock {
            TestVoidWebServiceMetadata()
        }

        // error: No exact matches in call to static method 'buildExpression'
        StandardComponentOnlyMetadataBlock {
            TestVoidComponentOnlyMetadata()
        }

        // error: No exact matches in call to static method 'buildExpression'
        StandardComponentMetadataBlock {
            TestVoidComponentMetadata()
        }

        StandardContentMetadataBlock {
            // error: No exact matches in call to static method 'buildExpression'
            TestVoidHandlerMetadata()

            // error: No exact matches in call to static method 'buildExpression'
            TestVoidWebServiceMetadata()

            // error: No exact matches in call to static method 'buildExpression'
            TestVoidComponentOnlyMetadata()

            // error: No exact matches in call to static method 'buildExpression'
            TestVoidComponentMetadata()

            TestVoidContentMetadata()
        }
    }
}
