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
import DeploymentTargetIoTRuntime
import ApodiniREST
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
        Group("aws_rand2") {
            TextHandler("")
                .operation(.create)
            AWS_RandomNumberGenerator(handlerId: .other)
        }.formDeploymentGroup(withId: "group_aws_rand2")
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
            .metadata(
                DeploymentDevice(.deployTest)
            )
        Text("the only constant")
            .operation(.delete)
            .metadata(
                DeploymentDevice(.deployTest)
            )
    }
    
    var configuration: Configuration {
        REST {
            OpenAPI()
        }
        ApodiniDeploy(
            runtimes: [LocalhostRuntime<Self>.self, LambdaRuntime<Self>.self, IoTRuntime<Self>.self],
            config: DeploymentConfig(
                defaultGrouping: .separateNodes,
                deploymentGroups: [
                    .allHandlers(ofType: Text.self, groupId: "TextHandlersGroup")
                ]
            )
        )
        SingleCommandConfiguration()
        MultipleCommandConfiguration()
    }

    var metadata: Metadata {
        Description("WebService Description")
    }
}
