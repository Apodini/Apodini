//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


import Foundation
import Apodini
import ApodiniREST
import ApodiniGRPC
import ApodiniGraphQL


// MARK: Data Structures

//enum Genre: String, Codable, CaseIterable, Hashable {
//    case doomMetal
//    case stonerDoom
//    case funeralDoom
//    case metalcore
//    case deathcore
//}

enum Genre: Int32, ProtobufEnum {
    case doomMetal
    case stonerDoom
    case funeralDoom
    case metalcore
    case deathcore
}


struct Album: Codable, Content, Hashable {
    let id: UUID
    let title: String
    let artist: String
    let genres: [Genre]
    let songs: [Song]
    
    init(id: UUID = UUID(), title: String, artist: String, genres: [Genre], songs: [Song]) {
        self.id = id
        self.title = title
        self.artist = artist
        self.genres = genres
        self.songs = songs
    }
}


struct Song: Codable, Content, Hashable {
    let title: String
}


enum MusicLibrary {
    static var albums: [Album] = [
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


extension Optional {
    func unwrapOrThrow() throws -> Wrapped {
        if let value = self {
            return value
        } else {
            throw NSError(domain: "de.lukaskollmer.ugh", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Unable to unwrap optional value of type'\(Self.self)', because it was nil."
            ])
        }
    }
}


// MARK: Handlers & WS


struct GetAlbumHandler: Handler {
    @Parameter(.http(.path)) var id: UUID
    
    //func handle() async throws -> Optional<Album> { // TODO this doesn't work w/ GQL? (handler returning an optional value...)
    //    MusicLibrary.albums.first(where: { $0.id == id })
    //}
    func handle() async throws -> Album {
        try MusicLibrary.albums.first(where: { $0.id == id }).unwrapOrThrow()
    }
}


struct SearchAlbumsHandler: Handler {
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


struct AddAlbumHandler: Handler {
    @Parameter var title: String
    @Parameter var artist: String
    @Parameter var genres: [Genre]
    @Parameter var songs: [Song]
    
    func handle() async throws -> Album {
        let album = Album(id: UUID(), title: title, artist: artist, genres: genres, songs: songs)
        MusicLibrary.albums.append(album)
        return album
    }
    
    var metadata: AnyHandlerMetadata {
        Operation(.create)
        EndpointName("AddAlbum")
    }
}


struct MusicLibraryWebService: Apodini.WebService {
    var content: some Component {
        Group("album") {
            GetAlbumHandler().endpointName("GetAlbum")
            Group("search") {
                SearchAlbumsHandler()
                    .endpointName("SearchAlbums")
            }
            Group("new") {
                AddAlbumHandler()
            }
            Group("all") {
                BlockBasedHandler<[Album]> { MusicLibrary.albums }
                    .endpointName("GetAllAlbums")
            }
        }
    }
}

