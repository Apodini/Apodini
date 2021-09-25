//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTest
@testable import Apodini
@testable import ApodiniMigration
@testable import ApodiniMigrator
@_implementationOnly import PathKit
import XCTVapor

struct ThrowingHandler: Handler {
    @Apodini.Parameter var throwing: Throwing
    
    func handle() -> Throwing {
        throwing
    }
}

struct BlobHandler: Handler {
    @Apodini.Parameter var mimeType: MimeType
    
    func handle() -> Blob {
        Blob(Data(), type: mimeType)
    }
}

struct MultiplyHandler: Handler {
    @Apodini.Parameter var lhs: Int
    @Apodini.Parameter(.http(.path)) var rhs: Int
    
    func handle() -> Int {
        lhs * rhs
    }
}

struct Throwing: Apodini.Content, Decodable {
    let makeRuntimeThrow: () -> Void
    
    func encode(to encoder: Encoder) throws {}
    
    init(from decoder: Decoder) throws {
        makeRuntimeThrow = {}
    }
}

struct MigratorWebService: WebService {
    var content: some Component {
        MultiplyHandler()
        ThrowingHandler()
            .operation(.create)
        Text("delete")
            .operation(.delete)
        BlobHandler()
            .operation(.update)
            .identified(by: "blob")
    }
    
    var configuration: Configuration {
        ApodiniMigratorTests.migratorConfig
    }
}

final class ApodiniMigratorTests: ApodiniTests {
    let testDirectory = Path("./\(UUID().uuidString)")
    
    static var sut: MigratorConfiguration<MigratorWebService>?
    
    static var migratorConfig: Configuration {
        sut ?? EmptyConfiguration()
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        
        try testDirectory.mkpath()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        Self.sut = nil
        try testDirectory.delete()
    }
    
    private func start() {
        MigratorWebService().start(app: app)
    }
    
    func testEmptyConfiguration() throws {
        Self.sut = .init()
        
        start()
        
        XCTAssertEqual(Self.migratorConfig.command._commandName, "migrator")
        XCTAssertEqual(Self.migratorConfig.command.configuration.subcommands.count, 3)
        
        XCTAssert(app.vapor.app.routes.all.isEmpty)
        
        XCTAssert(app.storage.get(MigrationGuideStorageKey.self) == nil)
        
        let document = try XCTUnwrap(app.storage.get(MigratorDocumentStorageKey.self))
        let multiplyEndpoint = try XCTUnwrap(document.endpoints.first { $0.deltaIdentifier == "multiplyHandler" })
        
        XCTAssertEqual(multiplyEndpoint.response, .scalar(.int))
        XCTAssertEqual(multiplyEndpoint.path, .init("/v1/{rhs}"))
        XCTAssertEqual(multiplyEndpoint.operation, .read)
        XCTAssertEqual(multiplyEndpoint.deltaIdentifier.rawValue, multiplyEndpoint.handlerName.lowerFirst)
        
        let blob = try XCTUnwrap(document.endpoints.first { $0.deltaIdentifier == "blob" })
        XCTAssertEqual(blob.response, .scalar(.data))
        
        XCTAssertEqual(blob.parameters.first?.typeInformation, try TypeInformation(type: MimeType.self))
    }
    
    func testDocumentDirectoryExport() throws {
        let documentExport: DocumentExportOptions = .directory(testDirectory.string, format: .yaml)
        Self.sut = MigratorConfiguration(documentConfig: .export(documentExport))
        
        start()
        
        let document = try XCTUnwrap(app.storage.get(MigratorDocumentStorageKey.self))
        let exportedDocument = try Document.decode(from: testDirectory + "\(document.fileName).yaml")
        
        XCTAssertEqual(document, exportedDocument)
    }
    
    func testDocumentEndpointExport() throws {
        let path = "api-spec"
        
        Self.sut = MigratorConfiguration(documentConfig: .export(.endpoint(path)))
        
        start()
        
        try app.vapor.app.test(.GET, path) { response in
            XCTAssertEqual(response.status, .ok)
            XCTAssertNoThrow(try response.content.decode(Document.self, using: JSONDecoder()))
        }
    }
    
    func testMigrationGuideCompareFromFile() throws {
        let emptyDocument = Document()
        let exportPath = try emptyDocument.write(at: testDirectory.string, fileName: emptyDocument.fileName)
        
        Self.sut = MigratorConfiguration(
            migrationGuideConfig: .compare(.file(exportPath), export: .directory(testDirectory.string))
        )
        
        start()
        
        let stored = try XCTUnwrap(app.storage.get(MigrationGuideStorageKey.self))
        
        let exported = try MigrationGuide.decode(from: testDirectory + "migration_guide.json")
        
        XCTAssertEqual(stored, exported)
        
        let changes = exported.changes
        XCTAssert(changes.contains { $0.element == .networking(target: .serverPath) })
        XCTAssert(changes.contains { $0.element == .endpoint("multiplyHandler", target: .`self`) })
        XCTAssert(changes.contains { $0.element == .endpoint("blob", target: .`self`) })
        XCTAssert(changes.contains { $0.element == .endpoint("throwingHandler", target: .`self`) })
        XCTAssert(changes.contains { $0.element == .endpoint("text", target: .`self`) })
        
        let addedModelChange = try XCTUnwrap(changes.first { $0.element.isModel } as? AddChange)
        XCTAssert(addedModelChange.elementID == "MimeType")
        
        if case let .element(anyCodable) = addedModelChange.added {
            XCTAssertEqual(anyCodable.typed(TypeInformation.self), try TypeInformation(type: MimeType.self))
        } else {
            XCTFail("Migration guide did not store the added model")
        }
    }
    
    func testMigrationGuideCompareFromResources() throws {
        let migrationGuideExport: MigrationGuideExportOptions = .paths(directory: testDirectory.string, endpoint: "guide")
        let documentExport: DocumentExportOptions = .init(format: .json)
        Self.sut = MigratorConfiguration(
            documentConfig: .export(documentExport),
            migrationGuideConfig: .compare(.resource(.module, fileName: "migrator_document", format: .json), export: migrationGuideExport)
        )
        
        start()
        
        let storedMigrationGuide = try XCTUnwrap(app.storage.get(MigrationGuideStorageKey.self))
        try app.vapor.app.test(.GET, "guide") { response in
            XCTAssertEqual(response.status, .ok)
            let migrationGuide = try response.content.decode(MigrationGuide.self, using: JSONDecoder())
            XCTAssertEqual(storedMigrationGuide, migrationGuide)
        }
    }
    
    func testMigrationGuideReadFromResources() throws {
        let endpointPath = "migration-guide"
        let resource: ResourceLocation = .resource(.module, fileName: "empty_migration_guide", format: .yaml)
        Self.sut = .init(migrationGuideConfig: .read(resource, export: .endpoint(endpointPath, format: .json)))
        
        start()
        
        try app.vapor.app.test(.GET, endpointPath) { response in
            XCTAssertEqual(response.status, .ok)
            let migrationGuide = try response.content.decode(MigrationGuide.self, using: JSONDecoder())
            XCTAssert(migrationGuide.changes.isEmpty)
        }
    }
    
    func testInvalidReadExport() throws {
        let resource: ResourceLocation = .file("404")
        let readOnly = "/readonly"
        Self.sut = .init(
            documentConfig: .export(.directory(readOnly)),
            migrationGuideConfig: .read(resource, export: .endpoint("not-found"))
        )
        
        start()
        
        XCTAssert(app.storage.get(MigrationGuideStorageKey.self) == nil)
        
        try app.vapor.app.test(.GET, "not-found") { response in
            XCTAssertEqual(response.status, .notFound)
        }
        
        XCTAssertThrowsError(try Document.decode(from: readOnly.asPath))
    }
    
    func testMigratorDocumentCommand() throws {
        Self.sut = .init()
        
        let commandType = MigratorDocument<MigratorWebService>.self
        var command = commandType.init()
        command.export = .directory(testDirectory.string)
        command.webService = .init()
        command.runWebService = false
        
        try command.run(app: app)
        
        XCTAssertEqual(commandType.configuration.commandName, "document")
        
        let document = try XCTUnwrap(app.storage.get(MigratorDocumentStorageKey.self))
        XCTAssertEqual(document.allModels(), [try TypeInformation(type: MimeType.self)])
    }
    
    func testMigratorCompareCommand() throws {
        Self.sut = .init()
        let documentPath = try XCTUnwrap(ResourceLocation.resource(.module, fileName: "migrator_document", format: .json).path)
        
        let commandType = MigratorCompare<MigratorWebService>.self
        
        var command = commandType.init()
        command.documentExport = .directory(testDirectory.string)
        command.migrationGuideExport = .directory(testDirectory.string)
        command.oldDocumentPath = documentPath
        command.webService = .init()
        command.runWebService = false
        
        try command.run(app: app)
        
        XCTAssertEqual(commandType.configuration.commandName, "compare")
        
        let document = try XCTUnwrap(app.storage.get(MigratorDocumentStorageKey.self))
        XCTAssertEqual(document.allModels(), [try TypeInformation(type: MimeType.self)])
        
        let migrationGuide = try XCTUnwrap(app.storage.get(MigrationGuideStorageKey.self))
        XCTAssertEqual(migrationGuide.id, try Document.decode(from: documentPath.asPath).id)
    }
    
    func testMigratorReadCommand() throws {
        Self.sut = .init()
        let guidePath = try XCTUnwrap(ResourceLocation.resource(.module, fileName: "empty_migration_guide", format: .yaml).path)
        
        let commandType = MigratorRead<MigratorWebService>.self
        
        var command = commandType.init()
        command.documentExport = .endpoint("api-document")
        command.migrationGuideExport = .directory(testDirectory.string)
        command.migrationGuidePath = guidePath
        command.webService = .init()
        command.runWebService = false
        
        XCTAssertNoThrow(try command.validate())
        
        try command.run(app: app)
        
        XCTAssertEqual(commandType.configuration.commandName, "read")
        
        let migrationGuide = try XCTUnwrap(app.storage.get(MigrationGuideStorageKey.self))
        XCTAssertEqual(migrationGuide, try MigrationGuide.decode(from: guidePath.asPath))
    }
    
    func testCustomHTTPConfig() throws {
        struct TestWebService: WebService {
            var content: some Component {
                Text("Hello World")
            }
            
            var configuration: Configuration {
                Migrator(documentConfig: .export(.endpoint("api-spec")))
                HTTPConfiguration(hostname: "1.2.3.4", port: 56)
            }
            
            var metadata: Metadata {
                Version(prefix: "78", major: 9)
            }
        }
        
        TestWebService().start(app: app)
        
        try app.vapor.app.test(.GET, "api-spec") { response in
            XCTAssertEqual(response.status, .ok)
            let document = try response.content.decode(Document.self, using: JSONDecoder())
            XCTAssertEqual(document.metaData.versionedServerPath, "http://1.2.3.4:56/789")
        }
    }
    
    func testLibraryGeneration() throws {
        Self.sut = MigratorConfiguration(documentConfig: .export(.directory(testDirectory.string)))
        
        start()
        
        let document = try XCTUnwrap(app.storage.get(MigratorDocumentStorageKey.self))
        
        let migrator = try ApodiniMigrator.Migrator(
            packageName: "TestPackage",
            packagePath: testDirectory.string,
            documentPath: (testDirectory + "\(document.fileName).json").string
        )
        
        XCTAssertNoThrow(try migrator.run())
        
        let swiftFiles = try testDirectory.recursiveSwiftFiles().map { $0.lastComponent }
        
        let modelNames = document.allModels().map { $0.typeString + .swift }
        
        modelNames.forEach { XCTAssert(swiftFiles.contains($0)) }
        
        let endpointFileNames = document.endpoints.map { $0.response.nestedTypeString + "+Endpoint" + .swift }.unique()
        
        endpointFileNames.forEach { XCTAssert(swiftFiles.contains($0)) }

        XCTAssert(swiftFiles.contains("Handler.swift"))
        XCTAssert(swiftFiles.contains("NetworkingService.swift"))
        XCTAssert(swiftFiles.contains("TestPackageTests.swift"))
    }
}
