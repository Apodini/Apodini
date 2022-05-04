//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
@testable import Apodini
@testable import ApodiniGraphQL
import ApodiniNetworking
import XCTApodini
import XCTApodiniNetworking
import ApodiniUtils
import XCTest
import GraphQL


// MARK: Test Input Types

enum Genre: String, Codable, CaseIterable, Hashable {
    case doomMetal
    case stonerDoom
    case funeralDoom
    case metalcore
    case deathcore
}


struct Album: Codable, Content, Hashable {
    let title: String
    let artist: String
    let genres: [Genre]
    let songs: [Song]
}


// A second version of the `Album` struct, with all properties optional.
// This is used to decode query responses, since depending on the fields we're querying, we might not be getting the full
// object back, in which case the decoding operation would fail with the full type.
struct AlbumQueryResponse: Decodable, Hashable {
    let title: String?
    let artist: String?
    let genres: [Genre]? // swiftlint:disable:this discouraged_optional_collection
    let songs: [Song]? // swiftlint:disable:this discouraged_optional_collection

    // swiftlint:disable:next discouraged_optional_collection
    init(title: String? = nil, artist: String? = nil, genres: [Genre]? = nil, songs: [Song]? = nil) {
        self.title = title
        self.artist = artist
        self.genres = genres
        self.songs = songs
    }
}

struct Song: Codable, Content, Hashable {
    let title: String
}


private enum MusicLibrary {
    static var albums: [Album] = []
    
    static let initialAlbums: [Album] = [
        Album(title: "Dopesmoker", artist: "Sleep", genres: [.doomMetal, .stonerDoom], songs: [
            Song(title: "Domesmoker"),
            Song(title: "Holy Mountain")
        ]),
        Album(title: "Under Acid Hoof", artist: "Acid Mammoth", genres: [.doomMetal], songs: [
            Song(title: "Them!"),
            Song(title: "Tree Of Woe"),
            Song(title: "Tusks Of Doom"),
            Song(title: "Jack The Riffer"),
            Song(title: "Under Acid Hoof")
        ]),
        Album(title: "The Call of the Wretched Sea", artist: "AHAB", genres: [.doomMetal, .funeralDoom], songs: [
            Song(title: "Below The Sun"),
            Song(title: "The Pacific"),
            Song(title: "Old Thunder"),
            Song(title: "Of The Monstrous Pictures Of Whales - Interludium"),
            Song(title: "The Sermon"),
            Song(title: "The Hunt"),
            Song(title: "Ahab's Oath")
        ]),
        Album(title: "Longing", artist: "Bell Witch", genres: [.doomMetal, .funeralDoom], songs: [
            Song(title: "Bales (Of Flesh)"),
            Song(title: "Rows (Of Endless Waves)"),
            Song(title: "Longing (The River Of Ash)"),
            Song(title: "Beneath The Mask"),
            Song(title: "I Wait"),
            Song(title: "Outro")
        ]),
        Album(title: "Far From Heaven", artist: "Fit For An Autopsy", genres: [.deathcore], songs: [
            Song(title: "Far From Heaven")
        ])
    ]
}


private struct FindBandsHandler: Handler {
    @Parameter var genre: Genre
    
    func handle() async throws -> Set<String> {
        MusicLibrary.albums
            .compactMap { $0.genres.contains(genre) ? $0.artist : nil }
            .intoSet()
    }
}


private struct FetchAlbumsHandler: Handler {
    @Parameter var artist: String?
    @Parameter var genre: Genre?
    @Parameter var title: String?
    @Parameter var songTitle: String?
    
    func handle() async throws -> [Album] {
        MusicLibrary.albums
            .filter { album in
                if let artist = artist, album.artist.localizedCaseInsensitiveContains(artist) {
                    return true
                }
                if let genre = genre, album.genres.contains(genre) {
                    return true
                }
                if let title = title, album.title.localizedCaseInsensitiveContains(title) {
                    return true
                }
                if let songTitle = songTitle, album.songs.contains(where: { $0.title.localizedCaseInsensitiveContains(songTitle) }) {
                    return true
                }
                // Simply return all albums if no filters were passed
                return artist == nil && title == nil && genre == nil && songTitle == nil
            }
    }
}


private struct AddAlbumHandler: Handler {
    @Parameter var title: String
    @Parameter var artist: String
    @Parameter var genres: [Genre]
    @Parameter var songs: [Song]
    
    func handle() async throws -> Album {
        let album = Album(title: title, artist: artist, genres: genres, songs: songs)
        MusicLibrary.albums.append(album)
        return album
    }
}


struct EchoHandlerResult<T: Codable & Equatable>: Codable, Apodini.Content, Equatable {
    let string: String
    let listOfStrings: [String]
    let listOfInts: [Int]
    let bool: Bool
    let url: URL
    let uuid: UUID
    let uint32: UInt32
    let uint64: UInt64
    let int32: Int32
    let int64: Int64
    let float: Float
    let double: Double
    let date: Date
    let data: Data
    let custom: T
}


private struct EchoHandler<T: Codable & Equatable>: Handler {
    @Parameter var string: String
    @Parameter var listOfStrings: [String]
    @Parameter var listOfInts: [Int]
    @Parameter var bool: Bool
    @Parameter var url: URL
    @Parameter var uuid: UUID
    @Parameter var uint32: UInt32
    @Parameter var uint64: UInt64
    @Parameter var int32: Int32
    @Parameter var int64: Int64
    @Parameter var float: Float
    @Parameter var double: Double
    @Parameter var date: Date
    @Parameter var data: Data
    @Parameter var custom: T
    
    func handle() -> EchoHandlerResult<T> {
        EchoHandlerResult(
            string: string,
            listOfStrings: listOfStrings,
            listOfInts: listOfInts,
            bool: bool,
            url: url,
            uuid: uuid,
            uint32: uint32,
            uint64: uint64,
            int32: int32,
            int64: int64,
            float: float,
            double: double,
            date: date,
            data: data,
            custom: custom
        )
    }
}


private struct TestWebService: WebService {
    var content: some Component {
        Text("Hello, there")
            .endpointName("root")
        BlockBasedHandler<[Genre]> { Genre.allCases }
            .endpointName("genres")
        FindBandsHandler()
            .endpointName("findBands")
        FetchAlbumsHandler()
            .endpointName("albums")
        AddAlbumHandler()
            .operation(.create)
            .endpointName("addAlbum")
        EchoHandler<Album>()
            .endpointName("echo")
        EchoHandler<Never>()
            .endpointName("echoNever")
    }
}


struct WrappedGraphQLResponse<T: Decodable>: Decodable {
    let data: T
}


// MARK: Tests

class GraphQLInterfaceExporterTests: XCTApodiniTest {
    struct TestGraphQLExporterCollection: ConfigurationCollection {
        var configuration: Configuration {
            GraphQL(graphQLEndpoint: "/graphql", enableGraphiQL: true, enableCustom64BitIntScalars: true)
        }
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        MusicLibrary.albums = MusicLibrary.initialAlbums
        TestGraphQLExporterCollection().configuration.configure(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        TestWebService().accept(visitor)
        visitor.finishParsing()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MusicLibrary.albums = MusicLibrary.initialAlbums
    }
    
    
    func testSimpleQueryAsGETRequest() throws {
        let input = """
            query {
                root
            }
            """.addingPercentEncoding(withAllowedCharacters: [])!
        try app.testable().test(.GET, "/graphql?query=\(input)") { res in
            XCTAssertEqual(res.status, .ok)
            struct Response: Codable, Equatable {
                let root: String
            }
            XCTAssertEqual(
                try res.bodyStorage.getFullBodyData(decodedAs: WrappedGraphQLResponse<Response>.self).data,
                .init(root: "Hello, there")
            )
        }
    }
    
    
    func testSimpleQueryAsPOSTRequestWithJSONPayload() throws {
        let input = ApodiniGraphQL.GraphQLRequest(
            query: "query { root }",
            variables: [:],
            operationName: nil
        )
        try app.testable().test(
            .POST,
            "/graphql",
            headers: HTTPHeaders { $0[.contentType] = .json },
            body: try JSONEncoder().encodeAsByteBuffer(input, allocator: ByteBufferAllocator())
        ) { res in
            XCTAssertEqual(res.status, .ok)
            struct Response: Codable, Equatable {
                let root: String
            }
            XCTAssertEqual(
                try res.bodyStorage.getFullBodyData(decodedAs: WrappedGraphQLResponse<Response>.self).data,
                .init(root: "Hello, there")
            )
        }
    }
    
    
    func testSimpleQueryAsPOSTRequestWithGraphQLPayload() throws {
        let input = """
            query {
                root
            }
            """
        try app.testable().test(
            .POST,
            "/graphql",
            headers: HTTPHeaders { $0[.contentType] = .graphQL },
            body: ByteBuffer(string: input)
        ) { res in
            XCTAssertEqual(res.status, .ok)
            struct Response: Codable, Equatable {
                let root: String
            }
            XCTAssertEqual(
                try res.bodyStorage.getFullBodyData(decodedAs: WrappedGraphQLResponse<Response>.self).data,
                .init(root: "Hello, there")
            )
        }
    }
    
    
    func testCustomScalarTypes() throws {
        let input = """
            query {
                echo(
                    string: "Hello, World!",
                    listOfStrings: ["Hello", "World"],
                    listOfInts: [-2, -1, 0, 1, 2],
                    bool: true,
                    url: "https://in.tum.de",
                    uuid: "3B68EBD7-057D-4477-8C6D-C03FDC541D2F",
                    uint32: 4294967292,
                    uint64: 427792345092,
                    int32: -2147483648,
                    int64: -3254582894236989,
                    float: -3.2145698142,
                    double: 3.14159265359,
                    date: "2022-02-01T19:17:58Z",
                    data: "SGVsbG8sIFdvcmxkCg==",
                    custom: { title: "Mirror Reaper", artist: "Bell Witch", genres: [doomMetal, funeralDoom], songs: [{ title: "Mirror Reaper" }] }
                ) {
                    string,
                    listOfStrings,
                    listOfInts,
                    bool,
                    url,
                    uuid,
                    uint32,
                    uint64,
                    int32,
                    int64,
                    float,
                    double,
                    date,
                    data,
                    custom { title, artist, genres, songs { title } }
                }
            }
            """
        try app.testable().test(
            .POST,
            "/graphql",
            headers: HTTPHeaders { $0[.contentType] = .graphQL },
            body: ByteBuffer(string: input)
        ) { res in
            XCTAssertEqual(res.status, .ok)
            struct Response: Codable, Equatable {
                let echo: EchoHandlerResult<Album>
            }
            let decoder = JSONDecoder()
            decoder.dataDecodingStrategy = .base64
            decoder.dateDecodingStrategy = .iso8601
            let response = try res.bodyStorage.getFullBodyData(decodedAs: WrappedGraphQLResponse<Response>.self, using: decoder).data.echo
            XCTAssertEqual(response, .init(
                string: "Hello, World!",
                listOfStrings: ["Hello", "World"],
                listOfInts: [-2, -1, 0, 1, 2],
                bool: true,
                url: URL(string: "https://in.tum.de")!,
                uuid: UUID(uuidString: "3B68EBD7-057D-4477-8C6D-C03FDC541D2F")!,
                uint32: 4294967292,
                uint64: 427792345092,
                int32: -2147483648,
                int64: -3254582894236989,
                float: -3.2145698142,
                double: 3.14159265359,
                date: ISO8601DateFormatter().date(from: "2022-02-01T19:17:58Z")!,
                data: Data(base64Encoded: "SGVsbG8sIFdvcmxkCg==")!,
                custom: .init(title: "Mirror Reaper", artist: "Bell Witch", genres: [.doomMetal, .funeralDoom], songs: [
                    .init(title: "Mirror Reaper")
                ])
            ))
        }
    }
    
    
    private func _testAlbumsQuery(
        parameters: [String: String],
        variables: [String: (type: String, value: Map)] = [:],
        expectedResponse: [AlbumQueryResponse]
    ) throws {
        let params: String = parameters.isEmpty ? "" : "(\(parameters.map { "\($0): \($1)" }.joined(separator: ", ")))"
        let gqlRequest = ApodiniGraphQL.GraphQLRequest(
            query: """
                query FindAlbums\(variables.isEmpty ? "" : "(\(variables.map { "$\($0): \($1.type)" }.joined(separator: ", ")))") {
                    albums\(params) {
                        title
                        artist
                        genres
                    }
                }
                """,
            variables: variables.mapValues(\.value),
            operationName: nil
        )
        try app.testable().test(
            .POST,
            "/graphql",
            headers: HTTPHeaders { $0[.contentType] = .json },
            body: try JSONEncoder().encodeAsByteBuffer(gqlRequest, allocator: ByteBufferAllocator())
        ) { res in
            XCTAssertEqual(res.status, .ok)
            struct Response: Decodable, Hashable {
                let albums: [AlbumQueryResponse]
            }
            XCTAssertEqualIgnoringOrder(
                try res.bodyStorage.getFullBodyData(decodedAs: WrappedGraphQLResponse<Response>.self).data.albums,
                expectedResponse
            )
        }
    }
    
    func testQueryWithDefaultParameters() throws {
        try _testAlbumsQuery(parameters: [:], expectedResponse: [
            AlbumQueryResponse(title: "Dopesmoker", artist: "Sleep", genres: [.doomMetal, .stonerDoom]),
            AlbumQueryResponse(title: "The Call of the Wretched Sea", artist: "AHAB", genres: [.doomMetal, .funeralDoom]),
            AlbumQueryResponse(title: "Under Acid Hoof", artist: "Acid Mammoth", genres: [.doomMetal]),
            AlbumQueryResponse(title: "Far From Heaven", artist: "Fit For An Autopsy", genres: [.deathcore]),
            AlbumQueryResponse(title: "Longing", artist: "Bell Witch", genres: [.doomMetal, .funeralDoom])
        ])
    }
    
    
    func testQueryWithOneParameter() throws {
        try _testAlbumsQuery(parameters: ["genre": "funeralDoom"], expectedResponse: [
            AlbumQueryResponse(title: "The Call of the Wretched Sea", artist: "AHAB", genres: [.doomMetal, .funeralDoom]),
            AlbumQueryResponse(title: "Longing", artist: "Bell Witch", genres: [.doomMetal, .funeralDoom])
        ])
        try _testAlbumsQuery(parameters: ["genre": "doomMetal"], expectedResponse: [
            AlbumQueryResponse(title: "Under Acid Hoof", artist: "Acid Mammoth", genres: [.doomMetal]),
            AlbumQueryResponse(title: "Dopesmoker", artist: "Sleep", genres: [.doomMetal, .stonerDoom]),
            AlbumQueryResponse(title: "Longing", artist: "Bell Witch", genres: [.doomMetal, .funeralDoom]),
            AlbumQueryResponse(title: "The Call of the Wretched Sea", artist: "AHAB", genres: [.doomMetal, .funeralDoom])
        ])
    }
    
    
    func testQueryWithVariables() throws {
        try _testAlbumsQuery(parameters: ["songTitle": "$songTitle"], variables: ["songTitle": ("String", "the")], expectedResponse: [
            AlbumQueryResponse(title: "Under Acid Hoof", artist: "Acid Mammoth", genres: [.doomMetal]),
            AlbumQueryResponse(title: "The Call of the Wretched Sea", artist: "AHAB", genres: [.doomMetal, .funeralDoom]),
            AlbumQueryResponse(title: "Longing", artist: "Bell Witch", genres: [.doomMetal, .funeralDoom])
        ])
    }
    
    
    func testMutation() throws {
        // Make sure the to-be-inserted album does not exist prior to the mutation
        try _testAlbumsQuery(parameters: ["title": "\"And I Return\""], expectedResponse: [])
        
        // Add the album
        let input = """
            mutation AddAlbum {
                addAlbum(
                    title: "...And I Return To Nothingness",
                    artist: "Lorna Shore",
                    genres: [deathcore],
                    songs: [
                        { title: "To The Hellfire" },
                        { title: "Of The Abyss" },
                        { title: "...And I Return To Nothingness" }
                    ]
                ) {
                    title
                    artist
                    genres
                    songs { title }
                }
            }
            """
        try app.testable().test(
            .POST,
            "/graphql",
            headers: HTTPHeaders { $0[.contentType] = .graphQL },
            body: ByteBuffer(string: input)
        ) { res in
            XCTAssertEqual(res.status, .ok)
            struct Response: Codable, Equatable {
                let addAlbum: Album
            }
            XCTAssertEqual(
                try res.bodyStorage.getFullBodyData(decodedAs: WrappedGraphQLResponse<Response>.self).data,
                .init(addAlbum: Album(title: "...And I Return To Nothingness", artist: "Lorna Shore", genres: [.deathcore], songs: [
                    Song(title: "To The Hellfire"),
                    Song(title: "Of The Abyss"),
                    Song(title: "...And I Return To Nothingness")
                ]))
            )
        }
        
        // Make sure it does exist after the mutation
        try _testAlbumsQuery(parameters: ["title": "\"And I Return\""], expectedResponse: [
            AlbumQueryResponse(title: "...And I Return To Nothingness", artist: "Lorna Shore", genres: [.deathcore])
        ])
    }
    
    
    func testGraphiQLEndpoint() throws {
        // We can't really test whether it works, but we can test that it's there...
        try app.testable().test(.GET, "/graphiql") { response in
            let responseHTML = try XCTUnwrap(response.bodyStorage.getFullBodyDataAsString())
            XCTAssert(responseHTML.contains("GraphiQL.createFetcher({ url: '\(app.httpConfiguration.uriPrefix)/graphql' });"))
        }
    }
}


func XCTAssertEqualIgnoringOrder<T: Hashable>(
    _ actual: [T],
    _ expected: [T],
    _ message: @autoclosure () -> String = "" ,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let actualCounts = actual.distinctElementCounts()
    let expectedCounts = expected.distinctElementCounts()
    if actualCounts == expectedCounts {
        return
    }
    var missingElements: [T] = []
    var superfluousElements: [T] = []
    let diff = expected.difference(from: actual).inferringMoves()
    for change in diff {
        switch change {
        case let .insert(offset: _, element, associatedWith: _):
            superfluousElements.append(element)
        case let .remove(offset: _, element, associatedWith: _):
            missingElements.append(element)
        }
    }
    
    var failureMsg = ""
    if !missingElements.isEmpty {
        failureMsg += "Missing elements:\n\(missingElements.map { "- \($0)" }.joined(separator: "\n"))\n"
    }
    if !superfluousElements.isEmpty {
        failureMsg += "Superfluous elements:\n\(superfluousElements.map { "- \($0)" }.joined(separator: "\n"))\n"
    }
    let customMsg = message()
    if !customMsg.isEmpty {
        failureMsg.append(customMsg)
    }
    XCTFail(failureMsg, file: file, line: line)
}
