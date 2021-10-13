@testable import Apodini
import XCTest

class ConfigurationBuilderTests: XCTestCase {
    struct SomeConfiguration: Configuration {
        func configure(_ app: Application) { }
    }

    struct CheckConfigurationTriggered: Configuration {
        let counter: ConfigureCounter

        func configure(_ app: Application) {
            counter.number += 1
        }
    }

    class ConfigureCounter {
        var number = 0
    }

    // swiftlint:disable implicitly_unwrapped_optional
    var app: Application!

    override func setUp() {
        super.setUp()
        app = Application()
    }

    override func tearDown() {
        app.shutdown()
        super.tearDown()
    }

    func testEmptyCollection() throws {
        struct EmptyCollection: ConfigurationCollection { }

        let testCollection = EmptyCollection()
        let configurations = try XCTUnwrap(testCollection.configuration as? [Configuration])

        XCTAssert(configurations.count == 1)
        XCTAssert(configurations[0] is EmptyConfiguration)
    }

    func testCollectionWithOneElement() throws {
        struct TestCollection: ConfigurationCollection {
            var configuration: Configuration {
                SomeConfiguration()
            }
        }

        let testCollection = TestCollection()
        let configurations = try XCTUnwrap(testCollection.configuration as? [Configuration])

        XCTAssert(configurations.count == 1)
        XCTAssert(configurations[0] is SomeConfiguration)
    }

    func testCollectionWithOneElementAndMethodCalls() throws {
        struct TestCollection: ConfigurationCollection {
            let counter = ConfigureCounter()

            var configuration: Configuration {
                CheckConfigurationTriggered(counter: counter)
            }
        }

        let testCollection = TestCollection()
        (testCollection.configuration as? [Configuration])?.configure(app)

        XCTAssert(testCollection.counter.number == 1)
    }

    func testCollectionWithMultipleElements() throws {
        struct TestCollection: ConfigurationCollection {
            var configuration: Configuration {
                SomeConfiguration()
                EmptyConfiguration()
                SomeConfiguration()
            }
        }

        let testCollection = TestCollection()
        let configurations = try XCTUnwrap(testCollection.configuration as? [Configuration])

        XCTAssert(configurations.count == 3)
        XCTAssert(configurations[0] is SomeConfiguration)
        XCTAssert(configurations[1] is EmptyConfiguration)
        XCTAssert(configurations[2] is SomeConfiguration)
    }

    func testCollectionWithMultipleElementsAndMethodCalls() throws {
        struct TestCollection: ConfigurationCollection {
            let counter = ConfigureCounter()

            var configuration: Configuration {
                CheckConfigurationTriggered(counter: counter)
                CheckConfigurationTriggered(counter: counter)
                CheckConfigurationTriggered(counter: counter)
            }
        }

        let testCollection = TestCollection()
        (testCollection.configuration as? [Configuration])?.configure(app)

        XCTAssert(testCollection.counter.number == 3)
    }
    
    func testCollectionWithSingleConditionalAndMethodCalls() throws {
        struct TestCollection: ConfigurationCollection {
            let triggerConditional: Bool

            var configuration: Configuration {
                if triggerConditional {
                    SomeConfiguration()
                }
            }
        }
        
        let testCollectionTrue = TestCollection(triggerConditional: true)
        let testCollectionFalse = TestCollection(triggerConditional: false)

        let configurationsTrue = try XCTUnwrap(testCollectionTrue.configuration as? [Configuration])
        let configurationsNestedTrue = try XCTUnwrap(configurationsTrue[0] as? [Configuration])

        XCTAssert(configurationsTrue.count == 1)
        XCTAssert(configurationsNestedTrue.count == 1)
        XCTAssert(configurationsNestedTrue[0] is SomeConfiguration)

        let configurationsFalse = try XCTUnwrap(testCollectionFalse.configuration as? [Configuration])

        XCTAssert(configurationsFalse.count == 1)
        XCTAssert(configurationsFalse[0] is EmptyConfiguration)
    }

    func testCollectionWithConditional() throws {
        struct TestCollection: ConfigurationCollection {
            let triggerConditional: Bool

            var configuration: Configuration {
                if triggerConditional {
                    SomeConfiguration()
                } else {
                    EmptyConfiguration()
                }
                SomeConfiguration()
            }
        }

        let testCollectionTrue = TestCollection(triggerConditional: true)
        let testCollectionFalse = TestCollection(triggerConditional: false)

        let configurationsTrue = try XCTUnwrap(testCollectionTrue.configuration as? [Configuration])
        let configurationsNestedTrue = try XCTUnwrap(configurationsTrue[0] as? [Configuration])

        XCTAssert(configurationsTrue.count == 2)
        XCTAssert(configurationsNestedTrue.count == 1)
        XCTAssert(configurationsNestedTrue[0] is SomeConfiguration)
        XCTAssert(configurationsTrue[1] is SomeConfiguration)

        let configurationsFalse = try XCTUnwrap(testCollectionFalse.configuration as? [Configuration])
        let configurationsNestedFalse = try XCTUnwrap(configurationsFalse[0] as? [Configuration])

        XCTAssert(configurationsFalse.count == 2)
        XCTAssert(configurationsNestedFalse.count == 1)
        XCTAssert(configurationsNestedFalse[0] is EmptyConfiguration)
        XCTAssert(configurationsFalse[1] is SomeConfiguration)
    }

    func testCollectionWithConditionalAndMethodCalls() throws {
        struct TestCollection: ConfigurationCollection {
            let counter = ConfigureCounter()
            let triggerConditional: Bool

            var configuration: Configuration {
                if triggerConditional {
                    CheckConfigurationTriggered(counter: counter)
                } else {
                    EmptyConfiguration()
                }
                CheckConfigurationTriggered(counter: counter)
            }
        }

        let testCollectionTrue = TestCollection(triggerConditional: true)
        (testCollectionTrue.configuration as? [Configuration])?.configure(app)

        XCTAssert(testCollectionTrue.counter.number == 2)

        let testCollectionFalse = TestCollection(triggerConditional: false)
        (testCollectionFalse.configuration as? [Configuration])?.configure(app)

        XCTAssert(testCollectionFalse.counter.number == 1)
    }

    func testCollectionWithNestedConditionalAndMethodCalls() throws {
        struct TestCollection: ConfigurationCollection {
            let counter = ConfigureCounter()
            let triggerConditional1: Bool
            let triggerConditional2: Bool

            var configuration: Configuration {
                if triggerConditional1 {
                    CheckConfigurationTriggered(counter: counter)
                    if !triggerConditional2 {
                        CheckConfigurationTriggered(counter: counter)
                    } else {
                        EmptyConfiguration()
                    }
                } else {
                    EmptyConfiguration()
                }
                CheckConfigurationTriggered(counter: counter)
            }
        }

        let testCollectionTrue = TestCollection(triggerConditional1: true, triggerConditional2: true)
        (testCollectionTrue.configuration as? [Configuration])?.configure(app)

        XCTAssert(testCollectionTrue.counter.number == 2)

        let testCollectionFalse = TestCollection(triggerConditional1: true, triggerConditional2: false)
        (testCollectionFalse.configuration as? [Configuration])?.configure(app)

        XCTAssert(testCollectionFalse.counter.number == 3)
    }
}
