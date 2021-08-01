//
//  ConfiguredLogger.swift
//  
//
//  Created by Philipp Zagar on 09.06.21.
//

import Foundation
import Logging
import Apodini
import ApodiniUtils
import ApodiniVaporSupport

@propertyWrapper
public struct ConfiguredLogger: DynamicProperty {
    @Environment(\.connection)
    var connection: Connection
    
    @Environment(\.logger)
    var logger: Logger
    
    @Environment(\.storage)
    var storage: Storage
    
    @Environment(\LoggerExporter.BlackboardMetadata.value)
    var blackboardMetadata
    
    @Environment(\ExporterTypeMetadata.value)
    var exporterTypeMetadata
    
    @State
    private var builtLogger: Logger?
    
    private var app: Application?
    
    private let id: UUID
    private let logLevel: Logger.Level?
    
    public var wrappedValue: Logger {
        get {
            if builtLogger == nil {
                builtLogger = .init(label: "org.apodini.observe.\(self.blackboardMetadata.endpointName)")
                
                // Identifies the current logger instance -> stays consitent for the lifetime of the associated handler
                builtLogger?[metadataKey: "logger-uuid"] = .string(UUID().description)
                
                let request = connection.request
                let loggingMetadata = request.loggingMetadata
                
                // Write remote address
                builtLogger?[metadataKey: "remoteAddress"] = .string(connection.remoteAddress?.description ?? "unknown")
                
                // Write event loop
                builtLogger?[metadataKey: "connectionEventLoop"] = .string(connection.eventLoop.description)
                
                // Write connection state
                builtLogger?[metadataKey: "connectionState"] = .string(connection.state.rawValue)
                
                // Write information metadata
                builtLogger?[metadataKey: "information"] = .dictionary(self.getInformationMetadata(from: connection.information))
                
                // Write request metadata
                builtLogger?[metadataKey: "request"] = .dictionary(self.getRequestMetadata(from: request, metadata: loggingMetadata))
                
                // Write endpoint metadata
                builtLogger?[metadataKey: "endpoint"] = .dictionary(self.getEndpointMetadata())
                
                
                // Set log level - configured either by user in the property wrapper, a CLI argument/configuration in Configuration of WebService (for all loggers, set a storage entry?) or default (which is .info for the StreamLogHandler - set by the Logging Backend, so the struct implementing the LogHandler)
                /// Prio 1: User specifies a `Logger.LogLevel` in the property wrapper for a specific `Handler`
                if let logLevel = self.logLevel {
                    builtLogger?.logLevel = logLevel
                    
                    /// If logging level is configured gloally
                    if let globalConfiguredLogLevel = storage.get(LoggerConfiguration.LoggingStorageKey.self)?.configuration.logLevel {
                        if logLevel < globalConfiguredLogLevel {
                            print("The global configured logging level is \(globalConfiguredLogLevel.rawValue) but Handler \(String(describing: loggingMetadata["endpoint"])) has logging level \(logLevel.rawValue) which is lower than the configured global logging level")
                        }
                        /// If logging level is automatically set to a default value
                    } else {
                        var globalLogLevel: Logger.Level
                        #if DEBUG
                        globalLogLevel = .debug
                        #else
                        globalLogLevel = .info
                        #endif
                        
                        if logLevel < globalLogLevel {
                            print("The global default logging level is \(globalLogLevel.rawValue) but Handler \(String(describing: loggingMetadata["endpoint"])) has logging level \(logLevel.rawValue) which is lower than the global default logging level")
                        }
                    }
                }
                /// Prio 2: User specifies a `Logger.LogLevel`either via a CLI argument or via a `LoggerConfiguration` in the configuration of the `WebService`
                else if let loggingConfiguraiton = storage.get(LoggerConfiguration.LoggingStorageKey.self)?.configuration {
                    builtLogger?.logLevel = loggingConfiguraiton.logLevel
                }
                /// Prio 3: No `Logger.LogLevel` specified by user, use defaul value according to environment (debug mode or release mode)
                else {
                    #if DEBUG
                    builtLogger?.logLevel = .debug
                    #else
                    builtLogger?.logLevel = .info
                    #endif
                }
            } else {
                /*
                 /// If Websocket -> Need to check if new parameters are passed -> Parse them again if the count doesn't match
                 */
                
                // Reevaluate logging metadata since parameters could have changed
                let request = connection.request
                let loggingMetadata = request.loggingMetadata
                
                // Not very pretty
                //if (loggingMetadata["exporter"] ?? "") == "WebSocketInterfaceExporter" {
                //    builtLogger?[metadataKey: "parameters"] = loggingMetadata["parameters"]
                //}
                
                // TODO: Check if the exporter is WebSocketInterfaceExporter, only then trigger request and connectionState parsing again
                // Write request metadata
                builtLogger?[metadataKey: "request"] = .dictionary(self.getRequestMetadata(from: request, metadata: loggingMetadata))
                
                // Write connection state
                builtLogger?[metadataKey: "connectionState"] = .string(connection.state.rawValue)
            }
            
            return builtLogger!
        }
    }
    
    /// Private initializer
    private init(id: UUID = UUID(), logLevel: Logger.Level? = nil) {
        self.id = id
        self.logLevel = logLevel
    }
    
    /// Creates a new `@ConfiguredLogger` without any arguments
    public init() {
        // We need to pass any argument otherwise we would call the same initializer again resulting in an infinite loop
        self.init(id: UUID())
    }
    
    /// Creates a new `@ConfiguredLogger` and specify a `Logger.Level`
    public init(logLevel: Logger.Level) {
        self.init(id: UUID(), logLevel: logLevel)
    }
}

extension ConfiguredLogger {
    private func getInformationMetadata(from informationSet: InformationSet) -> Logger.Metadata {
        informationSet.reduce(into: [:]) { partialResult, info in
            if let auth = info.value as? Authorization {
                // Since this is confidential data, we just log the authorization type
                partialResult[Authorization.header] = .string(auth.type)
            } else if let cookies = info.value as? Cookies {
                partialResult[Cookies.header] = .dictionary(
                    cookies.value.reduce(into: [:]) { partialResult, cookie in
                        partialResult[cookie.key] = .string(cookie.value)
                    }
                )
            } else if let etag = info.value as? ETag {
                partialResult[ETag.header] = .string(etag.rawValue)
            } else if let expires = info.value as? Expires {
                partialResult[Expires.header] = .string(expires.rawValue)
            } else if let redirectTo = info.value as? RedirectTo {
                partialResult[RedirectTo.header] = .string(redirectTo.rawValue)
            }
            // Since we just use HTTP Headers as Information at the moment, stick to those HTTP Headers
            else if let anyHTTPInformation = info.value as? AnyHTTPInformation {
                partialResult[anyHTTPInformation.key.key] = .string(anyHTTPInformation.value)
            }
        }
    }
    
    private func getRequestMetadata(from request: Request, metadata requestMetadata: Logger.Metadata) -> Logger.Metadata {
        var builtRequestMetadata: Logger.Metadata = ["parameters":.dictionary(.init())]
        
        builtRequestMetadata["description"] = .string(request.description)
        builtRequestMetadata["debugDescription"] = .string(request.debugDescription)
        
        // Leave out the parameters key since those need special treatment
        requestMetadata
            .filter { key, _ in
                key != "parameters"
            }.forEach { key, value in
                builtRequestMetadata[key] = value
            }
        
        guard let parameterMetadata = requestMetadata["parameters"]?.metadataDictionary else {
            return builtRequestMetadata
        }
        
        // Map parameter ID to actual parameter name
        for metadata in parameterMetadata {
            guard let parameterName = self.blackboardMetadata.endpointParameters.filter({ $0.id.uuidString == metadata.key }).first?.name else {
                continue
            }
            
            builtRequestMetadata["parameters"] = .dictionary(
                builtRequestMetadata["parameters"]!.metadataDictionary.merging([parameterName: metadata.value]) { (_, new) in new }
            )
        }
        
        return builtRequestMetadata
    }
    
    private func getEndpointMetadata() -> Logger.Metadata {
        var builtEndpointMetadata: Logger.Metadata = [:]
        
        builtEndpointMetadata["name"] = .string(self.blackboardMetadata.endpointName)
        builtEndpointMetadata["parameters"] = .array(self.blackboardMetadata.endpointParameters.map({ parameter in
            .string(parameter.description)
        }))
        builtEndpointMetadata["operation"] = .string(self.blackboardMetadata.operation.description)
        builtEndpointMetadata["endpointPath"] = .string(self.blackboardMetadata.endpointPathComponents.value.reduce(into: "", { partialResult, endpointPath in
            partialResult.append(contentsOf: endpointPath.description)
        }))
        builtEndpointMetadata["version"] = .string(self.blackboardMetadata.context.get(valueFor: APIVersionContextKey.self)?.debugDescription ?? "unknown")
        builtEndpointMetadata["handlerType"] = .string(String(describing: self.blackboardMetadata.anyEndpointSource.handlerType))
        builtEndpointMetadata["handlerReturnType"] = .string(String(describing: self.blackboardMetadata.handleReturnType.type))
        builtEndpointMetadata["serviceType"] = .string(self.blackboardMetadata.serviceType.rawValue)
        
        return builtEndpointMetadata
    }
}
