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

extension IoTDeploymentProvider: FileMonitorDelegate {
    func fileMonitorDidDetectChanges() {
        
    }
    
    
    func listenForChanges() throws {
        guard automaticRedeployment else { return }

        let promise = group.next().makePromise(of: Void.self)
    
        let fileMonitor = try FileMonitor(self.packageRootDir, promise: promise)
        fileMonitor.onChangeDetection = {
            
        }

        fileMonitor.listen()

        try promise.futureResult.wait()
    }
}

protocol FileMonitorDelegate {
    func fileMonitorDidDetectChanges()
}

class FileMonitor {
    let url: URL
    var sources: [DispatchSourceFileSystemObject] = []
    var isActive: Bool
    
    var onChangeDetection: (() -> Void)?
    
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
                self.onChangeDetection?()
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
