//
//  File.swift
//  File
//
//  Created by Felix Desiderato on 07/08/2021.
//

import Foundation
import ApodiniDeployBuildSupport
import Dispatch
import DeviceDiscovery
import Apodini
import ApodiniUtils
import Logging
import DeploymentTargetIoTCommon

fileprivate enum RedeploymentReason {
    case fileChange
    case topologyChange
}

extension IoTDeploymentProvider: FileMonitorDelegate {
    func fileMonitorDidDetectChanges() {
        
    }
    
    func listenForChanges() throws {
        guard automaticRedeployment else { return }

        let promise = group.next().makePromise(of: Void.self)
    
        let fileMonitor = try FileMonitor(self.packageRootDir, promise: promise)

        fileMonitor.listen()
        listenForTopologyChanges(promise)

        try promise.futureResult.wait()
        
        
    }
    
    func listenForTopologyChanges(_ promise: EventLoopPromise<Void>) {
        group.next().scheduleRepeatedAsyncTask(initialDelay: .zero, delay: .seconds(30), notifying: promise, { repeatedTask in
            do {
                let discovery = self.setup(for: self.searchableTypes[0])
                let result = try discovery
                    .run()
                    .map { results -> Void in
                        // we need to compare the results to see if a reployment is necessary
                        // Possible Options:
                        // 1. There can be new devices
                        // 2. The action results of an existing device changed
                        for result in results {
                            
                            let isNewDevice = self.results.compactMap { $0.device.ipv4Address }.contains(result.device.ipv4Address!)
                            if isNewDevice {
                                //TODO: asdf
                            }
                            let needsRedeployment = result.hasDifferActions(<#T##other: DiscoveryResult##DiscoveryResult#>)
                            
                            
                        }
                        // check for new device
                        let newDevices = results.filter { !self.results.contains($0) }
                        if !newDevices.isEmpty {
                            // new device found.
                            // Need to find what actions where successful and deploy the responding handler ids
                        }
                        
                        let 
                        
                        
                        guard results != self.results else {
                            // nothing changed, we can schedule next task
                            repeatedTask.cancel(promise: promise)
                            return ()
                        }
                        self.results = results
                        promise.succeed(())
                        return ()
                    }
                return result
            } catch {
                self.logger.error("An error \(error) occurred with listing for topology changes.")
                repeatedTask.cancel(promise: promise)
                return promise.futureResult
            }
        })
    }
    
    fileprivate func redeploy(reason: RedeploymentReason) {
        
    }
}

enum ComparingResult {
    case newDevice
    case foundEndDevices
}

extension DiscoveryResult {
    public static func == (lhs: DiscoveryResult, rhs: DiscoveryResult) -> Bool {
        guard let lhsIp = lhs.device.ipv4Address, let rhsIp = rhs.device.ipv4Address else {
            return false
        }
        return lhsIp == rhsIp &&
            lhs.device.identifier == rhs.device.identifier &&
            lhs.foundEndDevices == rhs.foundEndDevices
    }
    
    func hasDifferActions(_ other: DiscoveryResult) -> Bool {
        !self.foundEndDevices.filter { id, value in
            other.foundEndDevices[id] != value
        }.isEmpty
    }
    
    func hasDifferActions(_ others: [DiscoveryResult]) -> Bool {
        let other = others.filter {
            $0.device.ipv4Address == self.device.ipv4Address
        }
        
        
        for other in others {
            !self.foundEndDevices.filter { id, value in
                other.foundEndDevices[id] != value
            }.isEmpty
        }
    }
}

protocol FileMonitorDelegate {
    func fileMonitorDidDetectChanges()
}

class FileMonitor {
    let url: URL
    var sources: [DispatchSourceFileSystemObject] = []
    var isActive: Bool
    
    var delegate: FileMonitorDelegate?

    let promise: EventLoopPromise<Void>?

    init(_ url: URL, promise: EventLoopPromise<Void>?) throws {
        self.url = url
        self.promise = promise
        self.isActive = false
        
        let manager = FileManager.default
        let subDirs = try manager.allSubDirectories(for: url)
        
        self.sources = subDirs.map { dirUrl -> DispatchSourceFileSystemObject in
            IoTDeploymentProvider.logger.info("Creating listener for \(dirUrl.path)")
            let descriptor = open(dirUrl.path, O_EVTONLY)
            let source = DispatchSource
                .makeFileSystemObjectSource(
                    fileDescriptor: descriptor,
                    eventMask: [.all],
                    queue: .init(label: "queue_deployment_\(dirUrl.absoluteString)")
                )
            source.setEventHandler {
                IoTDeploymentProvider.logger.info("Detected changes in directory \(dirUrl.lastPathComponent)")
                self.promise?.succeed(())
            }

            return source
        }
    }
    
    func listen() {
        self.sources.forEach { $0.resume() }
        self.isActive = true
        IoTDeploymentProvider.logger.info("Listing for changes ..")
    }
    
    func pause() {
        self.sources.forEach { $0.suspend() }
        self.isActive = false
    }
}

extension FileManager {
    
    func allSubDirectories(for url: URL) throws -> [URL] {
        var allDirs: [URL] = [url]
        
        func subDirs(for url: URL) throws {
            let dirUrls = try self.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]).filter(\.hasDirectoryPath)
            guard !dirUrls.isEmpty else {
                return
            }
            allDirs.append(contentsOf: dirUrls)
            for dirUrl in dirUrls {
                try subDirs(for: dirUrl)
            }
        }
        
        try subDirs(for: url)
        
        return allDirs
    }
}
