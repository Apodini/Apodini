import Foundation
import NIO
import Apodini
import ApodiniDeploy
import DeploymentTargetLocalhostRuntime
import DeploymentTargetAWSLambdaRuntime
import ApodiniREST
import ApodiniOpenAPI
import ArgumentParser
import ApodiniDeploymentCLI

/// Used to test the two deployment providers (localhost and Lambda).
@main
public struct WebService: Apodini.WebService {
    public var content: some Component {
        Group("aws_rand") {
            Text2("").operation(.create)
            AWS_RandomNumberGenerator(handlerId: .main)
        }.formDeploymentGroup(withId: "group_aws_rand")
        Group("aws_rand2") {
            Text2("").operation(.create)
            AWS_RandomNumberGenerator(handlerId: .other)
        }.formDeploymentGroup(withId: "group_aws_rand2")
        Group("aws_greet") {
            AWS_Greeter()
                .deploymentOptions(
                    .memory(.mb(175)),
                    .timeout(.seconds(12))
                )
        }
        Group("lh_textmut") {
            LH_TextMut()
        }
        Group("lh_greet") {
            LH_Greeter()
        }
        Text("change is")
        Text("the only constant").operation(.delete)
    }
    
    public var configuration: Configuration {
        REST {
            OpenAPI()
        }
        ApodiniDeploy(
            runtimes: [LocalhostRuntime.self, LambdaRuntime.self],
            config: DeploymentConfig(
                defaultGrouping: .separateNodes,
                deploymentGroups: [
                    .allHandlers(ofType: Text.self, groupId: "TextHandlersGroup")
                ]
            )
        )
    }

    public var metadata: Metadata {
        Description("WebService Description")
    }
    
    public static var configuration: CommandConfiguration {
        CommandConfiguration(subcommands: [DeploymentCLI<Self>.self])
    }
    
    public init() {}
}
