public struct AnyConfigurationCollection: Configuration {
    public var configurations: [AnyConfiguration]
    
    
    public init(_ configs: [AnyConfiguration]) {
        self.configurations = configs
    }
    
    public init(_ configs: AnyConfiguration...) {
        self.configurations = configs
    }
    
    init (_ config: AnyConfiguration) {
        self.configurations = [config]
    }
}

extension AnyConfigurationCollection: Configurable {
    func configurable(by configurator: Configurator) {
        for config in configurations {
            config.configurable(by: configurator)
        }
    }
}

public struct AnyConfiguration: Configuration {
    private let _configurable: (_ configurator: Configurator) -> ()
    
    init<C: Configuration>(_ config: C) {
        self._configurable = config.configurable(by:)
    }
}

extension AnyConfiguration: Configurable {
    func configurable(by configurator: Configurator) {
        _configurable(configurator)
    }
}
