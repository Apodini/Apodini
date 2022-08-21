//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTest
@testable import Apodini
@testable import ApodiniAudit
@testable import ApodiniREST
import PythonKit


final class SelectionTests: ApodiniTests {
    func testWebServiceCategoryExclude() throws {
        try assertNoFinding(
            webService: WebService1(),
            bestPracticeType: URLPathSegmentLength.self,
            endpointPath: "/hi"
        )
    }
    
    func testHandlerScopeInclude() throws {
        try assertOneFinding(
            webService: WebService2(),
            bestPracticeType: URLPathSegmentLength.self,
            endpointPath: "/hi",
            expectedFinding: URLPathSegmentLengthFinding.segmentTooShort(segment: "hi")
        )
    }
    
    func testComponentBestPracticeInclude() throws {
        try assertOneFinding(
            webService: WebService3(),
            bestPracticeType: URLPathSegmentLength.self,
            endpointPath: "/hi",
            expectedFinding: URLPathSegmentLengthFinding.segmentTooShort(segment: "hi")
        )
    }
    
    struct WebService1: WebService {
        var content: some Component {
            Group("hi") {
                SomeHandler()
            }
        }

        @ConfigurationBuilder static var conf: Configuration {
            REST {
                APIAuditor()
            }
        }
        
        var configuration: Configuration {
            Self.conf
        }
        
        var metadata: AnyWebServiceMetadata {
            SelectBestPractices(.exclude, .urlPath)
        }
    }
    
    struct WebService2: WebService {
        var content: some Component {
            Group("hi") {
                SomeHandler()
                    .metadata(SelectBestPractices(.include, .rest))
            }
        }

        @ConfigurationBuilder static var conf: Configuration {
            REST {
                APIAuditor()
            }
        }
        
        var configuration: Configuration {
            Self.conf
        }
        
        var metadata: AnyWebServiceMetadata {
            SelectBestPractices(.exclude, .urlPath)
        }
    }
    
    struct WebService3: WebService {
        var content: some Component {
            Group("hi") {
                SomeHandler()
                    
            }
            .metadata(SelectBestPractices(.include, URLPathSegmentLength.self))
        }

        @ConfigurationBuilder static var conf: Configuration {
            REST {
                APIAuditor()
            }
        }
        
        var configuration: Configuration {
            Self.conf
        }
        
        var metadata: AnyWebServiceMetadata {
            SelectBestPractices(.exclude, .rest)
        }
    }
    
    struct SomeHandler: Handler {
        func handle() -> Response<String> {
            .send("")
        }
    }
}
