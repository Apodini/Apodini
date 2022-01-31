//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTest
import XCTApodini
@testable import Apodini
@testable import ApodiniMigration
@testable import RESTMigrator
@testable import ApodiniMigrator
@_implementationOnly import PathKit
@testable import ApodiniNetworking
import XCTApodiniNetworking
@testable import ApodiniDocumentExport


struct ThrowingHandler: Handler {
    @Apodini.Parameter var throwing: Throwing
    
    func handle() -> Throwing {
        throwing
    }
}

struct BlobHandler: Handler {
    @Apodini.Parameter var mediaType: HTTPMediaType
    
    func handle() -> Blob {
        Blob(Data(), type: mediaType)
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
        
        XCTAssert(app.httpServer.registeredRoutes.isEmpty)
        
        XCTAssert(app.storage.get(MigrationGuideStorageKey.self) == nil)
        
        let document = try XCTUnwrap(app.storage.get(MigratorDocumentStorageKey.self))
        let multiplyEndpoint = try XCTUnwrap(document.endpoints.first { $0.deltaIdentifier == "MultiplyHandler" })
        
        XCTAssertEqual(multiplyEndpoint.response, .scalar(.int))
        XCTAssertEqual(multiplyEndpoint.path, .init("/{rhs}"))
        XCTAssertEqual(multiplyEndpoint.operation, .read)
        XCTAssertEqual(multiplyEndpoint.deltaIdentifier.rawValue, multiplyEndpoint.handlerName.rawValue)
        
        let blob = try XCTUnwrap(document.endpoints.first { $0.deltaIdentifier == "blob" })
        XCTAssertEqual(blob.response, .scalar(.data))
        
        XCTAssertEqual(blob.parameters.first?.typeInformation, try TypeInformation(type: HTTPMediaType.self))
    }
    
    func testDocumentDirectoryExport() throws {
        let documentExport: DocumentExportOptions = .directory(testDirectory.string, format: .yaml)
        Self.sut = MigratorConfiguration(documentConfig: .export(documentExport))
        
        start()
        
        let document = try XCTUnwrap(app.storage.get(MigratorDocumentStorageKey.self))
        let exportedDocument = try APIDocument.decode(from: testDirectory + "\(document.fileName).yaml")
        
        XCTAssertEqual(document, exportedDocument)
    }
    
    func testDocumentEndpointExport() throws {
        let path = "api-spec"
        
        Self.sut = MigratorConfiguration(documentConfig: .export(.endpoint(path)))
        
        start()
        
        try app.testable().test(.GET, path) { response in
            XCTAssertEqual(response.status, .ok)
            XCTAssertNoThrow(try response.bodyStorage.getFullBodyData(decodedAs: APIDocument.self, using: JSONDecoder()))
        }
    }
    
    func testMigrationGuideCompareFromFile() throws {
        let emptyDocument = APIDocument(serviceInformation: ServiceInformation(
            version: .default,
            http: HTTPInformation(hostname: "127.0.0.1"),
            exporters: RESTExporterConfiguration(encoderConfiguration: .default, decoderConfiguration: .default)
        ))
        let exportPath = try emptyDocument.write(at: testDirectory.string, fileName: emptyDocument.fileName)
        
        Self.sut = MigratorConfiguration(
            migrationGuideConfig: .compare(.file(exportPath), export: .directory(testDirectory.string))
        )
        
        start()
        
        let stored = try XCTUnwrap(app.storage.get(MigrationGuideStorageKey.self))
        
        let exported = try MigrationGuide.decode(from: testDirectory + "migration_guide.json")
        
        XCTAssertEqual(stored, exported)

        XCTAssert(exported.serviceChanges.contains { change in
            if change.id == ServiceInformation.deltaIdentifier,
               case .http = change.modeledUpdateChange?.updated {
                return true
            }
            return false
        })

        XCTAssert(exported.endpointChanges.contains(where: { $0.id == "MultiplyHandler" && $0.type == .addition }))
        XCTAssert(exported.endpointChanges.contains(where: { $0.id == "blob" && $0.type == .addition }))
        XCTAssert(exported.endpointChanges.contains(where: { $0.id == "ThrowingHandler" && $0.type == .addition }))
        XCTAssert(exported.endpointChanges.contains(where: { $0.id == "Text" && $0.type == .addition }))

        let addedModelChange = try XCTUnwrap(exported.modelChanges.first?.modeledAdditionChange)
        XCTAssertEqual(addedModelChange.id, "HTTPMediaType")
        XCTAssertEqual(addedModelChange.added, try TypeInformation(type: HTTPMediaType.self))
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
        try app.testable().test(.GET, "guide") { response in
            XCTAssertEqual(response.status, .ok)
            let migrationGuide = try response.bodyStorage.getFullBodyData(decodedAs: MigrationGuide.self, using: JSONDecoder())
            XCTAssertEqual(storedMigrationGuide, migrationGuide)
        }
    }
    
    func testMigrationGuideReadFromResources() throws {
        let endpointPath = "migration-guide"
        let resource: ResourceLocation = .resource(.module, fileName: "empty_migration_guide", format: .yaml)
        Self.sut = .init(migrationGuideConfig: .read(resource, export: .endpoint(endpointPath, format: .json)))
        
        start()
        
        try app.testable().test(.GET, endpointPath) { response in
            XCTAssertEqual(response.status, .ok)
            let migrationGuide = try response.bodyStorage.getFullBodyData(decodedAs: MigrationGuide.self, using: JSONDecoder())
            XCTAssert(migrationGuide.serviceChanges.isEmpty)
            XCTAssert(migrationGuide.modelChanges.isEmpty)
            XCTAssert(migrationGuide.endpointChanges.isEmpty)
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
        
        try app.testable().test(.GET, "not-found") { response in
            XCTAssertEqual(response.status, .notFound)
        }
        
        XCTAssertThrowsError(try APIDocument.decode(from: Path(readOnly)))
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
        XCTAssertEqual(document.models, [try TypeInformation(type: HTTPMediaType.self)])
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
        XCTAssertEqual(document.models, [try TypeInformation(type: HTTPMediaType.self)])
        
        let migrationGuide = try XCTUnwrap(app.storage.get(MigrationGuideStorageKey.self))
        XCTAssertEqual(migrationGuide.id, try APIDocument.decode(from: Path(documentPath)).id)
    }
    
    func testMigratorReadCommand() throws {
        let mg = MigrationGuide.empty(id: UUID())
        print(mg.yaml)

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
        XCTAssertEqual(migrationGuide, try MigrationGuide.decode(from: Path(guidePath)))
    }
    
    func testCustomHTTPConfig() throws {
        struct TestWebService: WebService {
            var content: some Component {
                Text("Hello World")
            }
            
            var configuration: Configuration {
                Migrator(documentConfig: .export(.endpoint("api-spec")))
                HTTPConfiguration(hostname: Hostname(address: "1.2.3.4", port: 56), bindAddress: .interface("1.2.3.4", port: 56))
            }
            
            var metadata: Metadata {
                Version(prefix: "78", major: 9)
            }
        }
        
        TestWebService().start(app: app)
        
        try app.testable().test(.GET, "api-spec") { response in
            XCTAssertEqual(response.status, .ok)
            let document = try response.bodyStorage.getFullBodyData(decodedAs: APIDocument.self, using: JSONDecoder())
            XCTAssertEqual(document.serviceInformation.http.description, "1.2.3.4:56")
        }
    }
    
    func testLibraryGeneration() throws {
        Self.sut = MigratorConfiguration(documentConfig: .export(.directory(testDirectory.string)))
        
        start()
        
        let document = try XCTUnwrap(app.storage.get(MigratorDocumentStorageKey.self))

        let migrator = try RESTMigrator(documentPath: (testDirectory + "\(document.fileName).json").string)
        
        XCTAssertNoThrow(try migrator.run(packageName: "TestPackage", packagePath: testDirectory.string))
        
        let swiftFiles = try testDirectory.recursiveSwiftFiles().map { $0.lastComponent }
        
        let modelNames = document.models.map { $0.typeString + .swift }
        for modelName in modelNames {
            XCTAssert(swiftFiles.contains(modelName))
        }
        
        let endpointFileNames = document.endpoints.map { $0.response.nestedTypeString + "+Endpoint" + .swift }.unique()
        for fileName in endpointFileNames {
            XCTAssert(swiftFiles.contains(fileName))
        }

        XCTAssert(swiftFiles.contains("Handler.swift"))
        XCTAssert(swiftFiles.contains("NetworkingService.swift"))
        XCTAssert(swiftFiles.contains("TestPackageTests.swift"))
    }

    func testPatternMapping() {
        XCTAssertEqual(ApodiniMigratorCore.CommunicationalPattern(.requestResponse), .requestResponse)
        XCTAssertEqual(ApodiniMigratorCore.CommunicationalPattern(.serviceSideStream), .serviceSideStream)
        XCTAssertEqual(ApodiniMigratorCore.CommunicationalPattern(.clientSideStream), .clientSideStream)
        XCTAssertEqual(ApodiniMigratorCore.CommunicationalPattern(.bidirectionalStream), .bidirectionalStream)
    }
}
