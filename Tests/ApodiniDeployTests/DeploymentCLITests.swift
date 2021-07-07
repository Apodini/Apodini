//
//  DeploymentCLITests.swift
//  
//
//  Created by Felix Desiderato on 07/07/2021.
//

import Foundation
import XCTApodini
import ApodiniREST
import ApodiniOpenAPI
import ApodiniUtils
@testable import ApodiniDeploy
import ApodiniDeploymentCLI


class DeploymentCLITests: ApodiniDeployTestCase {
    func testDeploymentCommand() throws {
        let srcRoot = try Self.replicateApodiniSrcRootInTmpDir()
        
        let task = Task(
            executableUrl: Self.urlOfBuildProduct(named: Self.apodiniDeployTestWebServiceTargetName),
            arguments: ["deployment"],
            captureOutput: true,
            redirectStderrToStdout: true,
            // the tests are dynamically loaded into an `xctest` process, which doesn't statically load CApodiniUtils,
            // meaning we cannot detect child invocations, meaning we cannot launch children into that process group.
            launchInCurrentProcessGroup: false
        )
        let taskDidTerminateExpectation = XCTestExpectation("Task did terminate")
        taskDidTerminateExpectation.assertForOverFulfill = true
        
        let expectedAbstract = DeploymentCLI.configuration.abstract
        let expectedDiscussion = DeploymentCLI.configuration.discussion
        
        let stdioObserverHandle = task.observeOutput { _, data, _ in
            let text = XCTUnwrapWithFatalError(String(data: data, encoding: .utf8))
            XCTAssert(text.contains(expectedAbstract), text)
            XCTAssert(text.contains(expectedDiscussion), text)
        }
        
        let terminationInfo = try task.launchSync()
        XCTAssertEqual(terminationInfo.exitCode, EXIT_SUCCESS)
    }
}
