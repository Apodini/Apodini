//
//  ConfigurationConvertible.swift
//  
//
//  Created by Alexander Collins on 22.11.20.
//


public protocol ConfigurationConvertible {
    func eraseToAnyConfiguration() -> AnyConfiguration
}


extension EmptyConfiguration: ConfigurationConvertible {
    public func eraseToAnyConfiguration() -> AnyConfiguration {
        fatalError("\(type(of: self)) has no body")
    }
}


extension DatabaseConfiguration: ConfigurationConvertible  {
    public func eraseToAnyConfiguration() -> AnyConfiguration {
        AnyConfiguration(self)
    }
}


extension APNSConfiguration: ConfigurationConvertible  {
    public func eraseToAnyConfiguration() -> AnyConfiguration {
        AnyConfiguration(self)
    }
}
