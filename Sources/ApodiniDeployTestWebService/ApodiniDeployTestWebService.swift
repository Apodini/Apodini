//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import NIO
import Apodini
import ApodiniDeploy
import DeploymentTargetLocalhostRuntime
import DeploymentTargetAWSLambdaRuntime
import ApodiniREST
import ApodiniGRPC
import ApodiniOpenAPI


/// Used to test the two deployment providers (localhost and Lambda).
@main
struct WebService: Apodini.WebService {
    var content: some Component {
        Group("aws_rand") {
            TextHandler("")
                .operation(.create)
            AWS_RandomNumberGenerator(handlerId: .main)
        }.formDeploymentGroup(withId: "group_aws_rand")
        Group("aws_greet") {
            AWS_Greeter()
                .metadata {
                    Memory(.mb(175))
                    Timeout(.seconds(12))
                }
        }
        Group("lh_textmut") {
            LH_TextMut()
        }
        Group("lh_greet") {
            LH_Greeter()
        }
        Text("change is")
        Text("the only constant")
            .operation(.delete)
    }
    
    var configuration: Configuration {
        REST {
            OpenAPI()
        }
        HTTPConfiguration(
            bindAddress: .interface("localhost", port: 50051),
            tlsConfiguration: .init(
                certificatePath: Bundle.module.url(forResource: "apodini_https_cert_localhost.cer", withExtension: "pem")!.path,
                keyPath: Bundle.module.url(forResource: "apodini_https_cert_localhost.key", withExtension: "pem")!.path
            )
        )
        GRPC(packageName: "HelloWorld", serviceName: "HelloService")
        SingleCommandConfiguration()
        MultipleCommandConfiguration()
    }

    var metadata: Metadata {
        Description("WebService Description")
    }
}
