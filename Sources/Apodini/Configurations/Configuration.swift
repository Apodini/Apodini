//
//  Configuration.swift
//  
//
//  Created by Alexander Collins on 18.11.20.
//
import NIO
import Vapor

public protocol Configuration {
    associatedtype Config: Configuration = Never
    associatedtype ReturnType: Any = Never
    @ConfigurationBuilder var configuration: Self.Config { get }
    
    func configure(_ app: Application) -> Self.ReturnType
}


extension Never: Configuration {
    public typealias Config = Never
    public typealias ReturnType = Never
    
    public func configure(_ app: Application) -> Self.ReturnType {
        fatalError("should not happen")
    }
    
    public var configuration: Never {
        fatalError("should not happen")
    }
}

extension Configuration where Self.Config == Never {
    public var configuration: Never {
        fatalError("should not happen")
    }
}

extension Configuration where Self.ReturnType == Never {
    public func configure(_ app: Application) -> Never {
        print(Self.ReturnType.self)
        fatalError("should not happen")
    }
}

extension Configuration {
    
    func configurable(by configurator: Configurator) {
        if let configurable = self as? Configurable {
            configurable.configurable(by: configurator)
        } else if Self.Config.self != Never.self {
            configuration.configurable(by: configurator)
        } else {
            configurator.register(configuration: self)
        }
    }
    
}

public protocol ConfigurationCollection: Configuration {}

public struct EmptyConfiguration: Configuration {
    public func configure(_ app: Application) {
    }
    
    public init() {}
}

public protocol Test {
    func test()
}
