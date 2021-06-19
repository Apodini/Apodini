//
//  LambdaDeploymentProviderTests.swift
//
//
//  Created by Lukas Kollmer on 2021-04-23.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
import ApodiniUtils
import SotoIAM
import SotoS3
import SotoLambda
import SotoApiGatewayV2


class LambdaDeploymentProviderTests: ApodiniDeployTestCase {
    private var task: Task! // swiftlint:disable:this implicitly_unwrapped_optional
    private var taskStdioObserverToken: AnyObject?
    
    
    func testLambdaDeploymentProvider() throws { // swiftlint:disable:this function_body_length cyclomatic_complexity
        guard Self.shouldRunDeploymentProviderTests else {
            print("Skipping test case '\(#function)'.")
            return
        }
        
        let awsAccessKeyId: String
        let awsSecretAccessKey: String
        let awsRegionName: String
        let awsS3BucketName: String
        let awsS3BucketPath: String = "ApodiniDeployTests"
        let awsAPIGatewayAPIID: String
        
        do {
            awsAccessKeyId = try Self.readEnvironmentVariable("AWS_ACCESS_KEY_ID")
            awsSecretAccessKey = try Self.readEnvironmentVariable("AWS_SECRET_ACCESS_KEY")
            awsRegionName = try Self.readEnvironmentVariable("AWS_REGION")
            awsS3BucketName = try Self.readEnvironmentVariable("S3_BUCKET_NAME")
            awsAPIGatewayAPIID = (try? Self.readEnvironmentVariable("API_GATEWAY_ID")) ?? "_createNew"
        } catch {
            print("Error parsing environment: \(error)")
            print("Skipping test '\(#function)'.")
            return
        }
        
        
        let srcRoot = try Self.replicateApodiniSrcRootInTmpDir()
        
        task = Task(
            executableUrl: Self.urlOfBuildProduct(named: "DeploymentTargetAWSLambda"),
            arguments: [
                srcRoot.path,
                "--product-name", Self.apodiniDeployTestWebServiceTargetName,
                "--aws-region", awsRegionName,
                "--s3-bucket-name", awsS3BucketName,
                "--s3-bucket-path", awsS3BucketPath,
                "--aws-api-gateway-api-id", awsAPIGatewayAPIID
            ],
            workingDirectory: nil,
            captureOutput: true,
            redirectStderrToStdout: true,
            launchInCurrentProcessGroup: false,
            environment: [
                "AWS_ACCESS_KEY_ID": awsAccessKeyId,
                "AWS_SECRET_ACCESS_KEY": awsSecretAccessKey
            ],
            inheritsParentEnvironment: true
        )
        
        
        let taskDidFinishExpectation = XCTestExpectation("Task did finish")
        
        try task.launchAsync { [unowned self] terminationInfo in
            withoutContinuingAfterFailures {
                // If the deployment provider didn't succeed, there's no point in continuing...
                XCTAssertEqual(EXIT_SUCCESS, terminationInfo.exitCode)
            }
            taskDidFinishExpectation.fulfill()
        }
        
        var fullOutput = String(reservingCapacity: 10_000)
        
        taskStdioObserverToken = task.observeOutput { _, data, _ in
            let text = XCTUnwrapWithFatalError(String(data: data, encoding: .utf8))
            print(text, terminator: "")
            fullOutput += text
        }
        
        
        wait(for: [taskDidFinishExpectation], timeout: 60 * 45) // We give it *a ton* of time, just to be sure.
        
        taskStdioObserverToken = nil
        task = nil
        
        
        print("Waiting a bit so that the deployed resources are available")
        sleep(30)
        print("Investigate the deployed resources")
        
        // It's important that the test continues until the end, since we need to (at least attempt to) clean up the AWS resources...
        continueAfterFailure = true
        
        let output = fullOutput.components(separatedBy: .newlines)
        
        
        let s3Url: String = try {
            let regex = try NSRegularExpression(
                pattern: #"notice de\.lukaskollmer\.ApodiniLambda\.AWSIntegration : Uploading lambda package to (.*)$"#,
                options: [.anchorsMatchLines]
            )
            for line in output {
                let matches = regex.matches(in: line)
                guard let match = matches.first, matches.count == 1 else {
                    continue
                }
                return match.contentsOfCaptureGroup(atIndex: 1, in: line)
            }
            throw makeError(message: "Unable to find s3 upload url")
        }()
        
        XCTAssertEqual(s3Url, "s3://\(awsS3BucketName)/\(awsS3BucketPath)/lambda.out.zip")
        
        
        let (apiGatewayApiId, numDeployedLambdas) = try { () -> (String, Int) in
            let regex = try NSRegularExpression(
                pattern: #"Deployed (\d+) lambdas to api gateway w/ id '([a-z0-9]+)'$"#,
                options: .anchorsMatchLines
            )
            for line in output {
                let matches = regex.matches(in: line)
                guard let match = matches.first, matches.count == 1 else {
                    continue
                }
                return (
                    match.contentsOfCaptureGroup(atIndex: 2, in: line),
                    try XCTUnwrap(Int(match.contentsOfCaptureGroup(atIndex: 1, in: line)))
                )
            }
            throw makeError(message: "Unable to find API Gateway API ID")
        }()
        
        XCTAssertEqual(6, numDeployedLambdas)
        
        let (iamExecutionRoleName, _) = try { () -> (String, String) in
            let regex = try NSRegularExpression(
                pattern: #"Created lambda execution role: name='(.*)' arn='(.*)'$"#,
                options: .anchorsMatchLines
            )
            for line in output {
                let matches = regex.matches(in: line)
                guard let match = matches.first, matches.count == 1 else {
                    continue
                }
                return (
                    match.contentsOfCaptureGroup(atIndex: 1, in: line),
                    match.contentsOfCaptureGroup(atIndex: 2, in: line)
                )
            }
            throw makeError(message: "Unable to find Lambda Execution IAM Role")
        }()
        
        
        let lambdaFunctionNames: [String]
        do {
            let regex = try NSRegularExpression(
                pattern: #"Creating new lambda function (.*)$"#,
                options: .anchorsMatchLines
            )
            var names: [String] = []
            for line in output {
                let matches = regex.matches(in: line)
                guard let match = matches.first, matches.count == 1 else {
                    continue
                }
                names.append(match.contentsOfCaptureGroup(atIndex: 1, in: line))
            }
            lambdaFunctionNames = names
        }
        
        XCTAssertEqual(lambdaFunctionNames.count, numDeployedLambdas)
     
        
        let invokeUrl = "https://\(apiGatewayApiId).execute-api.\(awsRegionName).amazonaws.com/"
        
        do { // Check that the invoke url is correct
            let regex = try NSRegularExpression(
                pattern: #"notice de\.lukaskollmer\.ApodiniLambda\.AWSIntegration : Invoke URL: (.*)$"#,
                options: .anchorsMatchLines
            )
            for line in output {
                let matches = regex.matches(in: line)
                guard let match = matches.first, matches.count == 1 else {
                    continue
                }
                XCTAssertEqual(invokeUrl, match.contentsOfCaptureGroup(atIndex: 1, in: line))
            }
        }
        
        print("Send requests to lambda functions")
        
        do { // Send some test requests to the /v1/rand endpoint
            let numRandTests = 25
            let expectation = XCTestExpectation("Test /v1/aws_rand", expectedFulfillmentCount: numRandTests)
            for _ in 0..<numRandTests {
                try sendTestRequest(to: "/v1/aws_rand?lowerBound=7&upperBound=520", invokeUrl: invokeUrl) { httpResponse, data in
                    XCTAssertEqual(200, httpResponse.statusCode)
                    let randomValue = try JSONDecoder().decode(WrappedRESTResponse<Int>.self, from: data).data
                    XCTAssert((7...520).contains(randomValue))
                    expectation.fulfill()
                }.resume()
            }
            wait(for: [expectation], timeout: 10)
        }
        
        
        do {
            // Send a test request to the /v1/greet endpoint
            let expectation = XCTestExpectation("Test /v1/aws_greet")
            try sendTestRequest(to: "/v1/aws_greet/Lukas?age=22", invokeUrl: invokeUrl) { httpResponse, data in
                XCTAssertEqual(200, httpResponse.statusCode)
                do {
                    let responseString = try JSONDecoder().decode(WrappedRESTResponse<String>.self, from: data).data
                    let regex = try NSRegularExpression(
                        pattern: #"^Hello, (.*)\. Your random number in range (\d+)\.\.\.(\d+) is (\d+)!$"#,
                        options: []
                    )
                    let matches = regex.matches(in: responseString)
                    XCTAssertEqual(matches.count, 1)
                    let match = try XCTUnwrap(matches.first)
                    XCTAssertEqual("Lukas", match.contentsOfCaptureGroup(atIndex: 1, in: responseString))
                    XCTAssertEqual("22", match.contentsOfCaptureGroup(atIndex: 2, in: responseString))
                    XCTAssertEqual("44", match.contentsOfCaptureGroup(atIndex: 3, in: responseString))
                    let randValue = try XCTUnwrap(Int(match.contentsOfCaptureGroup(atIndex: 4, in: responseString)))
                    XCTAssert((22...44).contains(randValue))
                    XCTAssertEqual(5, match.numberOfRanges)
                    expectation.fulfill()
                } catch {
                    XCTFail("Error: \(error.localizedDescription)")
                }
            }.resume()
            wait(for: [expectation], timeout: 10)
        }
        
        
        print("Deleting AWS resources created as part of the test")
        
        let awsClient = AWSClient(
            credentialProvider: .static(accessKeyId: awsAccessKeyId, secretAccessKey: awsSecretAccessKey),
            retryPolicy: .default,
            httpClientProvider: .createNew
        )
        let awsRegion = try XCTUnwrap(SotoCore.Region(awsRegionName: awsRegionName))
        let iam = IAM(client: awsClient)
        let s3 = S3(client: awsClient, region: awsRegion)
        let lambda = Lambda(client: awsClient, region: awsRegion)
        let apiGateway = ApiGatewayV2(client: awsClient, region: awsRegion)
        
        do {
            print("Deleting s3 object")
            let response = try s3.deleteObject(.init(bucket: awsS3BucketName, key: "\(awsS3BucketPath)/lambda.out.zip")).wait()
            print(response)
            
            for functionName in lambdaFunctionNames {
                print("Deleting lambda function \(functionName)")
                try lambda.deleteFunction(.init(functionName: functionName)).wait()
            }
            
            if awsAPIGatewayAPIID == "_createNew" {
                print("Deleting API gateway")
                try apiGateway.deleteApi(.init(apiId: apiGatewayApiId)).wait()
            } else {
                print("Do not delete API gateway \(awsAPIGatewayAPIID) as it was passed to the test case as a specific argument")
            }
            
            let detachRolePolicy = { (arn: String) throws -> Void in
                print("Detaching policy from execution role. Role: '\(iamExecutionRoleName)' policy: \(arn)")
                try iam.detachRolePolicy(IAM.DetachRolePolicyRequest(
                    policyArn: arn,
                    roleName: iamExecutionRoleName
                )).wait()
            }
            
            try detachRolePolicy("arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole")
            try detachRolePolicy("arn:aws:iam::aws:policy/service-role/AWSLambdaRole")
            
            print("Deleting IAM Lambda execution role \(iamExecutionRoleName)")
            try iam.deleteRole(IAM.DeleteRoleRequest(roleName: iamExecutionRoleName)).wait()
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        print("Test complete, shutting down AWS client")
        try awsClient.syncShutdown()
    }
    
    
    private func sendTestRequest(
        to path: String, invokeUrl: String, responseValidator: @escaping (HTTPURLResponse, Data) throws -> Void
    ) throws -> URLSessionDataTask {
        let url = try XCTUnwrap(URL(string: "\(invokeUrl)\(path)"))
        print("Send Request to \(url)")
        return URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                XCTFail("Unexpected error in request: \(error.localizedDescription)")
                return
            }
            let msg = "request to '\(path)' failed."
            do {
                let response = try XCTUnwrap(response as? HTTPURLResponse, msg)
                let data = try XCTUnwrap(data, msg)
                try responseValidator(response, data)
            } catch {
                XCTFail("\(msg): \(error.localizedDescription)")
            }
        }
    }
}


extension XCTestCase {
    func withoutContinuingAfterFailures<T>(_ block: () throws -> T) rethrows -> T {
        let prevVal = continueAfterFailure
        continueAfterFailure = false
        defer {
            continueAfterFailure = prevVal
        }
        return try block()
    }
}
