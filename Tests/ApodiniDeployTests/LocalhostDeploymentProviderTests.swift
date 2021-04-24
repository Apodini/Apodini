//
//  LocalhostDeploymentProviderTests.swift
//  
//
//  Created by Lukas Kollmer on 2021-04-21.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
import ApodiniUtils


struct ResponseWithPid<T: Codable>: Codable {
    let pid: pid_t
    let value: T
    
    private init() {
        fatalError()
    }
}


class LocalhostDeploymentProviderTests: ApodiniDeployTestCase {
    static var deploymentProviderBin: URL {
        Self.urlOfBuildProduct(named: "DeploymentTargetLocalhost")
    }
    
    
    enum TestPhase: Int, Comparable, CustomStringConvertible {
        case launchWebService
        case sendRequests
        case shutdown
        case done
        
        /// Advance to the next phase, if possible.
        /// - returns: A boolean value indicating whether the phase was advanced to the next phase.
        @discardableResult
        mutating func advance() -> Bool {
            if self != .done {
                self = Self(rawValue: rawValue + 1)!
                return true
            } else {
                return false
            }
        }
        
        static func < (lhs: Self, rhs: Self) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
        
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
    
    
    private var task: Task!
    private var stdioObserverHandle: AnyObject!
    private var currentPhase: TestPhase = .launchWebService
    
    
    func testLocalhostDeploymentProvider() throws {
        let testRoot = try Self.createTestWebServiceDirStructure()
//        let testRoot = URL(fileURLWithPath: "/private/var/folders/72/gdk4ykgs6bdg2kds9pynlhzc0000gn/T/ADT_03D6198F-0742-4219-B2B6-FCCD134F59E2")
        print("TEST ROOT", testRoot)
        
        print(#file)
        
        let srcRoot: String = {
            let components = URL(fileURLWithPath: #filePath).pathComponents
            let expectedTrailingComponents = ["Tests", "ApodiniDeployTests", "LocalhostDeploymentProviderTests.swift"]
            let index = components.count - expectedTrailingComponents.count // index of the 1st expected trailing component
            // index = components.index(components.endIndex, offsetBy: expectedTrailingComponents.count + 1, limitedBy: components.startIndex)!
            // If the paths don't match, there's no point in continuing execution...
            continueAfterFailure = false
            XCTAssertEqual(
                expectedTrailingComponents[...],
                components[index...]
            )
            continueAfterFailure = true
            //return components[...components.index(components.startIndex, offsetBy: expectedTrailingComponents.count, limitedBy: <#T##Int#>)]
//            components[0..<index].joined(separator: FileManager.)
            return components[..<index].joined(separator: FileManager.pathSeparator)
        }()
        
        
        precondition(task == nil)
        
        task = Task(
            executableUrl: Self.deploymentProviderBin,
            arguments: [testRoot.path, "--product-name", "ADTestWebService"],
            //workingDirectory: <#T##URL?#>,
            captureOutput: true,
            redirectStderrToStdout: true,
            // the tests are dynamically loaded into an `xctest` process, which doesn't statically load CApodiniUtils,
            // meaning we cannot detect child invocations, meaning we cannot launch children into that process group.
            launchInCurrentProcessGroup: false,
            environment: ["LKApodiniSourceRoot": srcRoot]
        )
        
        
        /// Expectation that the deployment provider runs, computes the deployment, and launches the web service.
        let launchDPExpectation = XCTestExpectation(description: "Run deployment provider & launch web service")
        
        // Request handling expectations
        let responseExpectation_v1 = XCTestExpectation(
            "Web Service response for /v1/ request",
            expectedFulfillmentCount: 1,
            assertForOverFulfill: true
        )
        let responseExpectation_v1TextMut = XCTestExpectation(
            "Web Service response for /v1/textMut/ request",
            expectedFulfillmentCount: 1,
            assertForOverFulfill: true
        )
        let responseExpectation_v1Greeter = XCTestExpectation(
            "Web Service response for /v1/greet/ request",
            expectedFulfillmentCount: 1,
            assertForOverFulfill: true
        )
        
        /// Expectation that the servers spawned as part of launching the web service are all shut down
        let didShutDownServersExpectation = XCTestExpectation(
            "Did shut down servers",
            expectedFulfillmentCount: 4,
            assertForOverFulfill: false // hmmmmmmmmmm
        )
        /// Expectation that the task terminated. This is used to keep the test case running as long as the task is still running
        let taskDidTerminateExpectation = XCTestExpectation(description: "Task did terminate")
        
        /// The output collected for the current phase, separated by newlines
        var currentPhaseOutput = Array<String>(reservingCapacity: 1000)
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
            previousOutputDidEndWithNewline = text.hasSuffix("\n") // TODO platform-independence! (CharSet.newlines, if that API wasnt cursed af)
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
        
        stdioObserverHandle = task.observeOutput { stdioType, data, task in
            let text = String(data: data, encoding: .utf8)!
            handleOutput(text, printToStdout: true)
            
            // We're in the phase which is checking whether the web service sucessfully launched.
            // This is determined by finding the text `Server starting on http://127.0.0.1:5001` three times,
            // with the port numbers matching the expected output values (i.e. 5000, 5001, 5002 if no explicit port was specified).
            
            let serverLaunchedRegex = try! NSRegularExpression(
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
                    port: Int(matches[0].contentsOfCaptureGroup(atIndex: 2, in: line))!
                )
            }
            
            if startedServers.count == 4 {
                XCTAssertEqualIgnoringOrder(startedServers, [
                    // the gateway
                    StartedServerInfo(ipAddress: "127.0.0.1", port: 8080),
                    // the nodes
                    StartedServerInfo(ipAddress: "127.0.0.1", port: 5000),
                    StartedServerInfo(ipAddress: "127.0.0.1", port: 5001),
                    StartedServerInfo(ipAddress: "127.0.0.1", port: 5002)
                ])
                launchDPExpectation.fulfill()
            } else if startedServers.count < 4 {
                //print("servers were started, but not four. servers: \(startedServers.map { "\($0.ipAddress):\($0.port)" })")
            }
        }
        
        
        // Wait for the first phase to complete.
        // We give the deployment provider 25 minutes to compile and launch the web service.
        // This timeout is significantly larger than the other ones because the compilation step
        // needs to fetch and compile all dependencies of the web service, the deployment provider, and Apodini,
        // which can take a long time.
        wait(for: [launchDPExpectation], timeout: 60 * 25) // TODO 25
        
        resetOutput()
        stdioObserverHandle = nil
        
        
        // ------------------------------------------------------------------------------------ //
        // second test phase: send some requests to the web service and see how it handles them //
        // ------------------------------------------------------------------------------------ //
        
        
        func sendTestRequest(
            to path: String, responseValidator: @escaping (HTTPURLResponse, Data) throws -> Void
        ) -> URLSessionDataTask {
            return URLSession.shared.dataTask(with: URL(string: "http://127.0.0.1:8080\(path)")!) { data, response, error in
                if let error = error {
                    XCTFail("Unexpected error in request: \(error.localizedDescription)")
                    return
                }
                //print(path, response, data, data.flatMap { String(data: $0, encoding: .utf8) })
                let msg = "request to '\(path)' failed."
                do {
                    let response = try XCTUnwrap(response as? HTTPURLResponse, msg)
                    //XCTAssertEqual(response.statusCode, 200, msg)
                    let data = try XCTUnwrap(data, msg)
                    try responseValidator(response, data)
                    //let decodedResponse = try JSONDecoder().decode(WrappedRESTResponse<T>.self, from: data).data
                    //XCTAssertEqual(expectedResponse, decodedResponse, msg)
                    //expectation.fulfill()
                } catch {
                    XCTFail("\(msg): \(error.localizedDescription)")
                }
            }
        }
        
        sendTestRequest(to: "/v1/") { httpResponse, data in
            XCTAssertEqual(200, httpResponse.statusCode)
            let response = try JSONDecoder().decode(WrappedRESTResponse<String>.self, from: data).data
            XCTAssertEqual(response, "change is")
            responseExpectation_v1.fulfill()
        }.resume()
        
        
        let textMutPid = ThreadSafeVariable<pid_t?>(nil)
        
        sendTestRequest(to: "/v1/textmut/?text=TUM") { httpResponse, data in
            XCTAssertEqual(200, httpResponse.statusCode)
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
            responseExpectation_v1TextMut.fulfill()
        }.resume()
        
        
        sendTestRequest(to: "/v1/greet/Lukas/") { httpResponse, data in
            XCTAssertEqual(200, httpResponse.statusCode)
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
            responseExpectation_v1Greeter.fulfill()
        }.resume()
        
        
        // Wait for the second phase to complete.
        // This phase sends some requests to the deployed web service and checks that they were handled correctly.
        // We give it 20 seconds just to be safe
        wait(for: [
            responseExpectation_v1,
            responseExpectation_v1Greeter,
            responseExpectation_v1TextMut
        ], timeout: 20, enforceOrder: false)
        
        
        
        // -------------------------------------- //
        // third test phase: shut everything down //
        // -------------------------------------- //
        
        resetOutput()
        task.terminate()
        
        stdioObserverHandle = task.observeOutput { stdioType, data, task in
            let text = String(data: data, encoding: .utf8)!
            for _ in 0..<(text.components(separatedBy: "Application shutting down [pid=").count - 1) {
                NSLog("shutDownServers_a.fulfill() %i", didShutDownServersExpectation.assertForOverFulfill)
                didShutDownServersExpectation.fulfill()
            }
            if text.contains("notice DeploymentTargetLocalhost.ProxyServer : shutdown") {
                NSLog("shutDownServers_b.fulfill() %i", didShutDownServersExpectation.assertForOverFulfill)
                didShutDownServersExpectation.fulfill()
            }
        }
        
        // aaaaaaaargh
        //wait(for: [taskDidTerminateExpectation, didShutDownServersExpectation], timeout: 25, enforceOrder: false)
        
        // Destroy the observer token, thus deregistering the underlying observer.
        // The important thing here is that we need to make sure the lifetimes of the observer token and the task
        // extend all the way down here, so that we can know for a fact that the tests above work properly
        stdioObserverHandle = nil
        task = nil
    }
}




extension NSTextCheckingResult {
    func contentsOfCaptureGroup(atIndex idx: Int, in string: String) -> String {
        precondition((0..<numberOfRanges).contains(idx), "Invalid capture group index")
        guard let range = Range(self.range(at: idx), in: string) else {
            fatalError("Unable to construct 'Range<String.Index>' from NSRange")
        }
        return String(string[range])
    }
}


extension RangeReplaceableCollection {
    public init(reservingCapacity capacity: Int) {
        self.init()
        self.reserveCapacity(capacity)
    }
}


extension XCTestExpectation {
    convenience init(_ description: String, expectedFulfillmentCount: Int = 1, assertForOverFulfill: Bool = false) {
        self.init(description: description)
        self.expectedFulfillmentCount = expectedFulfillmentCount
        self.assertForOverFulfill = assertForOverFulfill
    }
}
