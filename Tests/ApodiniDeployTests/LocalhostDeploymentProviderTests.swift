//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTApodini
import ApodiniUtils
import AsyncHTTPClient


struct ResponseWithPid<T: Codable>: Codable {
    let pid: pid_t
    let value: T
    
    @available(*, unavailable)
    private init() {
        fatalError("Type '\(Self.self)' cannot be initialised")
    }
}


class LocalhostDeploymentProviderTests: ApodiniDeployTestCase {
    enum TestPhase: Int, CustomStringConvertible {
        case launchWebService
        case sendRequests
        case shutdown
        case done
        
        var description: String {
            switch self {
            case .launchWebService:
                return "\(Self.self).launchWebService"
            case .sendRequests:
                return "\(Self.self).sendRequests"
            case .shutdown:
                return "\(Self.self).shutdown"
            case .done:
                return "\(Self.self).done"
            }
        }
    }
    
    
    private var task: ChildProcess! // swiftlint:disable:this implicitly_unwrapped_optional
    private var stdioObserverHandle: AnyObject! // swiftlint:disable:this implicitly_unwrapped_optional
    private var currentPhase: TestPhase = .launchWebService
    
    
    func testLocalhostDeploymentProvider() throws { // swiftlint:disable:this function_body_length
        try XCTSkipUnless(Self.shouldRunDeploymentProviderTests)
        
        runShellCommand(.killPort(80))
        runShellCommand(.killPort(5000))
        runShellCommand(.killPort(5001))
        runShellCommand(.killPort(5002))
        runShellCommand(.killPort(5003))
        runShellCommand(.killPort(5004))
        runShellCommand(.killPort(5005))
        
        precondition(task == nil)
        
        let srcRoot = try Self.replicateApodiniSrcRootInTmpDir()
        
        task = ChildProcess(
            executableUrl: Self.urlOfBuildProduct(named: "DeploymentTargetLocalhost"),
            arguments: [srcRoot.path, "--product-name", Self.apodiniDeployTestWebServiceTargetName],
            captureOutput: true,
            redirectStderrToStdout: true,
            // the tests are dynamically loaded into an `xctest` process, which doesn't statically load CApodiniUtils,
            // meaning we cannot detect child invocations, meaning we cannot launch children into that process group.
            launchInCurrentProcessGroup: false
        )
        
        let expectedNumberOfNodes = 6
        
        /// Expectation that the deployment provider runs, computes the deployment, and launches the web service.
        let launchDPExpectation = XCTestExpectation("Run deployment provider & launch web service")
        
        // Request handling expectations
        let responseExpectationV1 = XCTestExpectation("Web Service response for /v1/ request")
        let responseExpectationV1TextMut = XCTestExpectation("Web Service response for /v1/textMut/ request")
        let responseExpectationV1Greeter = XCTestExpectation("Web Service response for /v1/greet/ request")
        
        /// Expectation that the servers spawned as part of launching the web service are all shut down
        let didShutDownNodesExpectation = XCTestExpectation(
            "Did shut down servers",
            expectedFulfillmentCount: expectedNumberOfNodes,
            assertForOverFulfill: true
        )
        /// Expectation that the gateway server is shut down
        let didShutDownGateway = XCTestExpectation("ChildProcess did terminate")
        didShutDownGateway.assertForOverFulfill = true
        /// Expectation that the task terminated. This is used to keep the test case running as long as the task is still running
        let taskDidTerminateExpectation = XCTestExpectation("ChildProcess did terminate")
        taskDidTerminateExpectation.assertForOverFulfill = true
        
        /// The output collected for the current phase, separated by newlines
        var currentPhaseOutput: [String] = .init(reservingCapacity: 1000)
        /// The output collected for the current line
        var currentLineOutput = String(reservingCapacity: 250)
        /// Whether the previously collected output ended with a line break
        var previousOutputDidEndWithNewline = false
        
        func handleOutput(_ text: String, printToStdout: Bool = false) {
            if printToStdout {
                print("\(previousOutputDidEndWithNewline ? "[DP] " : "")\(text)", terminator: "")
                fflush(stdout)
            }
            currentLineOutput.append(text)
            previousOutputDidEndWithNewline = text.hasSuffix("\n")
            if previousOutputDidEndWithNewline {
                currentPhaseOutput.append(contentsOf: currentLineOutput.components(separatedBy: .newlines))
                currentLineOutput.removeAll(keepingCapacity: true)
            }
        }
        
        func resetOutput() {
            previousOutputDidEndWithNewline = false
            currentPhaseOutput.removeAll(keepingCapacity: true)
            currentLineOutput.removeAll(keepingCapacity: true)
        }
        
        
        try task.launchAsync { _ in
            taskDidTerminateExpectation.fulfill()
        }
        
        
        // ---------------------------------------------------------------- //
        // First Test Phase: Run Deployment Provider and Launch Web Service //
        // ---------------------------------------------------------------- //
        
        resetOutput()
        precondition(stdioObserverHandle == nil)
        
        stdioObserverHandle = task.observeOutput { _, data, _ in
            let text = XCTUnwrapWithFatalError(String(data: data, encoding: .utf8))
            handleOutput(text, printToStdout: true)
            
            // We're in the phase which is checking whether the web service sucessfully launched.
            // This is determined by finding the text `Server starting on http://localhost:5001` three times,
            // with the port numbers matching the expected output values (i.e. 5000, 5001, 5002 if no explicit port was specified).
            
            let serverLaunchedRegex = try! NSRegularExpression( // swiftlint:disable:this force_try
                pattern: #"Server starting on http://(\d+\.\d+\.\d+\.\d+):(\d+)$"#,
                options: [.anchorsMatchLines]
            )
            
            struct StartedServerInfo: Hashable, Equatable {
                let ipAddress: String
                let port: Int
            }
            
            let startedServers: [StartedServerInfo] = currentPhaseOutput.compactMap { line in
                let matches = serverLaunchedRegex.matches(in: line, options: [], range: NSRange(line.startIndex..<line.endIndex, in: line))
                guard matches.count == 1 else {
                    return nil
                }
                return StartedServerInfo(
                    ipAddress: matches[0].contentsOfCaptureGroup(atIndex: 1, in: line),
                    port: XCTUnwrapWithFatalError(Int(matches[0].contentsOfCaptureGroup(atIndex: 2, in: line)))
                )
            }
            
            if startedServers.count == expectedNumberOfNodes + 1 {
                XCTAssertEqualIgnoringOrder(startedServers, [
                    // the gateway
                    StartedServerInfo(ipAddress: "0.0.0.0", port: 80),
                    // the nodes
                    StartedServerInfo(ipAddress: "0.0.0.0", port: 5000),
                    StartedServerInfo(ipAddress: "0.0.0.0", port: 5001),
                    StartedServerInfo(ipAddress: "0.0.0.0", port: 5002),
                    StartedServerInfo(ipAddress: "0.0.0.0", port: 5003),
                    StartedServerInfo(ipAddress: "0.0.0.0", port: 5004),
                    StartedServerInfo(ipAddress: "0.0.0.0", port: 5005)
                ])
                launchDPExpectation.fulfill()
            } else if startedServers.count < expectedNumberOfNodes {
                //print("servers were started, but not \(expectedNumberOfNodes). servers: \(startedServers.map { "\($0.ipAddress):\($0.port)" })")
            } else {
                //print("servers were started, but not \(expectedNumberOfNodes). servers: \(startedServers.map { "\($0.ipAddress):\($0.port)" })")
            }
        }
        
        
        // Wait for the first phase to complete.
        // We give the deployment provider 30 minutes to compile and launch the web service.
        // This timeout is significantly larger than the other ones because the compilation step
        // needs to fetch and compile all dependencies of the web service, the deployment provider, and Apodini,
        // which can take a long time.
        wait(for: [launchDPExpectation], timeout: 30 * 60)
        
        resetOutput()
        stdioObserverHandle = nil
        
        
        // ------------------------------------------------------------------------------------ //
        // second test phase: send some requests to the web service and see how it handles them //
        // ------------------------------------------------------------------------------------ //
        
        let httpClient = HTTPClient(eventLoopGroupProvider: .createNew)
        
        func sendTestRequest(
            to path: String, responseValidator: @escaping (HTTPClient.Response, ByteBuffer) throws -> Void
        ) throws {
//            let url = try XCTUnwrap(URL(string: "http://localhost\(path)"))
//            return URLSession.shared.dataTask(with: url) { data, response, error in
//                if let error = error {
//                    XCTFail("Unexpected error in request to \(url): \(error.localizedDescription)")
//                    return
//                }
//                let msg = "request to '\(path)' failed."
//                do {
//                    let response = try XCTUnwrap(response as? HTTPURLResponse, msg)
//                    let data = try XCTUnwrap(data, msg)
//                    print("""
//                        Got response for req to '\(path)':
//                        - response: \(response)
//                        - data: \(data) (as JSON: \(Result.init(catching: { try JSONSerialization.jsonObject(with: data, options: []) })))
//                        """
//                    )
//                    try responseValidator(response, data)
//                } catch {
//                    XCTFail("\(msg): \(error.localizedDescription)")
//                }
//            }
            let msg = "request to '\(path)' failed."
            let response = try httpClient.execute(.GET, url: "http://localhost\(path)").wait()
            let body = try XCTUnwrap(response.body, msg)
            do {
                try responseValidator(response, body)
            } catch {
                XCTFail("\(msg): \(error.localizedDescription)")
            }
        }
        
        print("Will start 1st test")
        try sendTestRequest(to: "/v1/") { httpResponse, data in
            XCTAssertEqual(.ok, httpResponse.status)
            let response = try JSONDecoder().decode(WrappedRESTResponse<String>.self, from: data).data
            XCTAssertEqual(response, "change is")
            responseExpectationV1.fulfill()
            print("did finish 1st test")
        }
        
        
        print("Will start 2nd test")
        let textMutPid = ThreadSafeVariable<pid_t?>(nil)
        
        try sendTestRequest(to: "/v1/lh_textmut/?text=TUM") { httpResponse, data in
            XCTAssertEqual(.ok, httpResponse.status)
            let response = try JSONDecoder().decode(WrappedRESTResponse<ResponseWithPid<String>>.self, from: data).data
            XCTAssertEqual("tum", response.value)
            textMutPid.write { pid in
                if let pid = pid {
                    // A pid has already been set (by the greeter request) so lets check that it matches the pid from this request
                    XCTAssertEqual(pid, response.pid)
                } else {
                    pid = response.pid
                }
            }
            responseExpectationV1TextMut.fulfill()
            print("did finish 2nd test")
        }
        
        
        print("Will start 3rd test")
        try sendTestRequest(to: "/v1/lh_greet/Lukas/") { httpResponse, data in
            XCTAssertEqual(.ok, httpResponse.status)
            struct GreeterResponse: Codable {
                let text: String
                let textMutPid: pid_t
            }
            let response = try JSONDecoder().decode(WrappedRESTResponse<ResponseWithPid<GreeterResponse>>.self, from: data).data
            XCTAssertEqual("Hello, lukas!", response.value.text)
            textMutPid.write { pid in
                if let pid = pid {
                    XCTAssertEqual(pid, response.value.textMutPid)
                } else {
                    pid = response.value.textMutPid
                }
            }
            XCTAssertNotEqual(response.pid, response.value.textMutPid)
            responseExpectationV1Greeter.fulfill()
            print("did finish 3rd test")
        }
        
        
        print("will wait")
        // Wait for the second phase to complete.
        // This phase sends some requests to the deployed web service and checks that they were handled correctly.
        // We give it 20 seconds just to be safe
        wait(
            for: [responseExpectationV1, responseExpectationV1Greeter, responseExpectationV1TextMut],
            timeout: 15,
            enforceOrder: false
        )
        
        print("will shutdown httpClient")
        try httpClient.syncShutdown()
        print("did shutdown httpClient")
        
        resetOutput()
        stdioObserverHandle = nil
        
        
        // -------------------------------------- //
        // third test phase: shut everything down //
        // -------------------------------------- //
        
        resetOutput()
        task.terminate()
        
        stdioObserverHandle = task.observeOutput { _, data, _ in
            let text = XCTUnwrapWithFatalError(String(data: data, encoding: .utf8))
            handleOutput(text, printToStdout: true)
            for _ in 0..<(text.components(separatedBy: "Application shutting down [pid=").count - 1) {
                didShutDownNodesExpectation.fulfill()
                NSLog("shutDownServers_a.fulfill() %i", didShutDownNodesExpectation.assertForOverFulfill)
            }
            if text.contains("Did shut down proxy server") {
                didShutDownGateway.fulfill()
                NSLog("shutDownServers_b.fulfill() %i", didShutDownGateway.assertForOverFulfill)
            }
        }
        
        wait(for: [taskDidTerminateExpectation, didShutDownNodesExpectation, didShutDownGateway], timeout: 60, enforceOrder: false)
        
        // Destroy the observer token, thus deregistering the underlying observer.
        // The important thing here is that we need to make sure the lifetimes of the observer token and the task
        // extend all the way down here, so that we can know for a fact that the tests above work properly
        stdioObserverHandle = nil
        task = nil
        
        XCTAssertApodiniApplicationNotRunning()
    }
}
