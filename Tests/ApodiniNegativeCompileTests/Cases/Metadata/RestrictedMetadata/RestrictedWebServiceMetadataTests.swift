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
        TestVoidWebServiceMetadata()

        WebServiceVoids {
            TestVoidWebServiceMetadata()

            // error: No exact matches in call to static method 'buildExpression'
            Description("Hello World!")
        }

        // error: Argument type 'AnyHandlerMetadata' does not conform to expected type 'AnyWebServiceMetadata'
        HandlerVoids {
            TestVoidHandlerMetadata()
        }

        ComponentVoids {
            TestVoidComponentMetadata()
        }

        // error: Argument type 'AnyComponentOnlyMetadata' does not conform to expected type 'AnyWebServiceMetadata'
        ComponentOnlyVoids {
            TestVoidComponentOnlyMetadata()
        }

        // error: no exact matches in call to static method 'buildExpression'
        ContentVoids {
            TestVoidContentMetadata()
        }
    }
}
