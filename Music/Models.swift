import SwiftUI
import Foundation

struct MusicCatalog {
    let playlists: [Playlist]
    let albums: [Album]
    let tracks: [Track]
    let podcasts: [Podcast]
    let genres: [Genre]

    var usesLocalTracks: Bool {
        tracks.contains { $0.source == .imported || $0.source == .musicFolder || $0.source == .bundle }
    }

    var sourceMessage: String {
        if tracks.contains(where: { $0.source == .imported }) {
            return "Songs loaded from imported files"
        }

        if tracks.contains(where: { $0.source == .musicFolder }) {
            return "Songs loaded from /Users/kanna/Music"
        }

        if tracks.contains(where: { $0.source == .bundle }) {
            return "Songs loaded from app bundle"
        }

        return "Add audio files to /Users/kanna/Music or the Music target"
    }

    static var local: MusicCatalog {
        let importedTracks = Track.importedAudioTracks()
        let musicFolderTracks = Track.musicFolderTracks()
        let bundledTracks = Track.bundleAudioTracks()
        let localTracks = firstNonEmpty([importedTracks, musicFolderTracks, bundledTracks])

        return MusicCatalog(
            playlists: [
                Playlist(title: "Liked Songs", iconName: "heart.fill", colors: [.purple, .blue]),
                Playlist(title: "Daily Mix 1", iconName: "music.note", colors: [.orange, .pink]),
                Playlist(title: "Discover Weekly", iconName: "sparkles", colors: [.green, .mint]),
                Playlist(title: "Chill Hits", iconName: "moon.stars.fill", colors: [.indigo, .cyan]),
                Playlist(title: "Top Artists", iconName: "person.2.fill", colors: [.red, .orange]),
                Playlist(title: "Release Radar", iconName: "dot.radiowaves.left.and.right", colors: [.teal, .blue])
            ],
            albums: [
                Album(title: "Late Night Drive", subtitle: "Synth pop and neon favorites", iconName: "car.fill", colors: [.pink, .purple]),
                Album(title: "Focus Flow", subtitle: "Instrumentals for deep work", iconName: "brain.head.profile", colors: [.blue, .teal]),
                Album(title: "Fresh Finds", subtitle: "New songs picked for you", iconName: "leaf.fill", colors: [.green, .yellow]),
                Album(title: "Acoustic Morning", subtitle: "Soft songs to start slow", iconName: "guitars.fill", colors: [.brown, .orange])
            ],
            tracks: localTracks.isEmpty ? demoTracks : localTracks,
            podcasts: [
                Podcast(title: "The Daily Mixdown", host: "Kanna Radio", colors: [.green, .teal]),
                Podcast(title: "Stories Behind Songs", host: "Studio Notes", colors: [.purple, .pink]),
                Podcast(title: "New Music Friday Talk", host: "Release Desk", colors: [.orange, .red])
            ],
            genres: [
                Genre(title: "Made For You", iconName: "person.crop.circle.fill", colors: [.blue, .purple]),
                Genre(title: "Charts", iconName: "chart.bar.fill", colors: [.pink, .red]),
                Genre(title: "New Releases", iconName: "sparkles", colors: [.green, .teal]),
                Genre(title: "Live Events", iconName: "ticket.fill", colors: [.orange, .yellow]),
                Genre(title: "Hip-Hop", iconName: "mic.fill", colors: [.indigo, .blue]),
                Genre(title: "Pop", iconName: "star.fill", colors: [.purple, .pink]),
                Genre(title: "Mood", iconName: "face.smiling.fill", colors: [.cyan, .mint]),
                Genre(title: "Podcasts", iconName: "headphones", colors: [.brown, .orange])
            ]
        )
    }

    static let preview = MusicCatalog(
        playlists: [
            Playlist(title: "Liked Songs", iconName: "heart.fill", colors: [.purple, .blue]),
            Playlist(title: "Preview Mix", iconName: "music.note", colors: [.green, .teal])
        ],
        albums: [
            Album(title: "Preview Album", subtitle: "Lightweight preview data", iconName: "sparkles", colors: [.pink, .purple])
        ],
        tracks: [
            Track(title: "Preview Song", artist: "Preview Artist", iconName: "music.note", colors: [.green, .teal], streamURLString: nil),
            Track(title: "Searchable Track", artist: "Preview Band", iconName: "waveform", colors: [.orange, .pink], streamURLString: nil)
        ],
        podcasts: [
            Podcast(title: "Preview Podcast", host: "Preview Host", colors: [.blue, .cyan])
        ],
        genres: [
            Genre(title: "Made For You", iconName: "person.crop.circle.fill", colors: [.blue, .purple]),
            Genre(title: "Podcasts", iconName: "headphones", colors: [.brown, .orange])
        ]
    )

    private static let demoTracks = [
            Track(title: "Dai Dai", artist: "Shakira, Burna Boy", iconName: "flame.fill", colors: [.orange, .red], streamURLString: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"),
            Track(title: "SaWaDiKa", artist: "LISA", iconName: "bolt.fill", colors: [.pink, .purple], streamURLString: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3"),
            Track(title: "Blinding Lights", artist: "The Weeknd", iconName: "sun.max.fill", colors: [.red, .orange], streamURLString: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3"),
            Track(title: "Levitating", artist: "Dua Lipa", iconName: "sparkle", colors: [.purple, .pink], streamURLString: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3"),
            Track(title: "As It Was", artist: "Harry Styles", iconName: "circle.grid.cross.fill", colors: [.cyan, .blue], streamURLString: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3"),
            Track(title: "Anti-Hero", artist: "Taylor Swift", iconName: "star.fill", colors: [.indigo, .mint], streamURLString: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3")
        ]

    private static func firstNonEmpty(_ trackGroups: [[Track]]) -> [Track] {
        trackGroups.first { !$0.isEmpty } ?? []
    }
}

struct Playlist: Identifiable {
    let id = UUID()
    let title: String
    let iconName: String
    let colors: [Color]
}

struct Album: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let iconName: String
    let colors: [Color]
}

struct Podcast: Identifiable {
    let id = UUID()
    let title: String
    let host: String
    let colors: [Color]
}

struct Track: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let iconName: String
    let colors: [Color]
    let streamURLString: String?
    let source: TrackSource

    var streamURL: URL? {
        streamURLString.flatMap(URL.init(string:))
    }

    init(title: String, artist: String, iconName: String, colors: [Color], streamURLString: String?, source: TrackSource = .stream) {
        self.title = title
        self.artist = artist
        self.iconName = iconName
        self.colors = colors
        self.streamURLString = streamURLString
        self.source = source
    }

    static func bundleAudioTracks() -> [Track] {
        let extensions = ["mp3", "m4a", "wav", "aac"]
        let subdirectories: [String?] = [nil, "Songs", "Music"]
        var foundURLs: [URL] = []
        var seenPaths = Set<String>()

        for subdirectory in subdirectories {
            for fileExtension in extensions {
                let urls = Bundle.main.urls(forResourcesWithExtension: fileExtension, subdirectory: subdirectory) ?? []

                for url in urls where !seenPaths.contains(url.path) {
                    seenPaths.insert(url.path)
                    foundURLs.append(url)
                }
            }
        }

        return foundURLs
            .sorted { $0.deletingPathExtension().lastPathComponent < $1.deletingPathExtension().lastPathComponent }
            .enumerated()
            .map { index, url in
                let title = url.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " ")

                return Track(
                    title: cleanTitle(from: title),
                    artist: "Local Music",
                    iconName: "music.note",
                    colors: colorPair(for: index),
                    streamURLString: url.absoluteString,
                    source: .bundle
                )
            }
    }

    static func importedAudioTracks() -> [Track] {
        audioTracks(
            at: ImportedSongStore.importDirectory,
            artistFallback: "Imported Music",
            source: .imported
        )
    }

    static func musicFolderTracks() -> [Track] {
        let musicFolderURL = URL(fileURLWithPath: "/Users/kanna/Music", isDirectory: true)
        return audioTracks(at: musicFolderURL, artistFallback: "Kanna Music", source: .musicFolder)
    }

    private static func audioTracks(at folderURL: URL, artistFallback: String, source: TrackSource) -> [Track] {
        let allowedExtensions = Set(["mp3", "m4a", "wav", "aac"])

        guard let enumerator = FileManager.default.enumerator(
            at: folderURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        let urls = enumerator.compactMap { item -> URL? in
            guard let url = item as? URL else {
                return nil
            }

            guard allowedExtensions.contains(url.pathExtension.lowercased()) else {
                return nil
            }

            return url
        }

        return urls
            .sorted { $0.deletingPathExtension().lastPathComponent < $1.deletingPathExtension().lastPathComponent }
            .enumerated()
            .map { index, url in
                let rawTitle = url.deletingPathExtension().lastPathComponent

                return Track(
                    title: cleanTitle(from: rawTitle),
                    artist: artistName(from: url, fallback: artistFallback),
                    iconName: "music.note",
                    colors: colorPair(for: index),
                    streamURLString: url.absoluteString,
                    source: source
                )
            }
    }

    private static func cleanTitle(from fileName: String) -> String {
        fileName
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "[www.SenSongsMp3.co]", with: "")
            .replacingOccurrences(of: "SenSongsMp3.Co", with: "")
            .replacingOccurrences(of: "SenSongsMp3.co", with: "")
            .replacingOccurrences(of: "SenSongsmp3.Co", with: "")
            .replacingOccurrences(of: "SenSongsMp3.Com", with: "")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: CharacterSet(charactersIn: " -"))
    }

    private static func artistName(from url: URL, fallback: String) -> String {
        let parentName = url.deletingLastPathComponent().lastPathComponent

        guard parentName != "Music" && parentName != ImportedSongStore.importDirectory.lastPathComponent else {
            return fallback
        }

        return parentName
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func colorPair(for index: Int) -> [Color] {
        let pairs: [[Color]] = [
            [.green, .teal],
            [.purple, .blue],
            [.orange, .pink],
            [.indigo, .cyan],
            [.red, .orange]
        ]

        return pairs[index % pairs.count]
    }
}

enum TrackSource {
    case bundle
    case imported
    case musicFolder
    case stream
}

enum ImportedSongStore {
    static var importDirectory: URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent("ImportedSongs", isDirectory: true)
    }

    static func importFiles(from urls: [URL]) throws -> Int {
        try FileManager.default.createDirectory(at: importDirectory, withIntermediateDirectories: true)

        var importedCount = 0

        for sourceURL in urls {
            let didAccess = sourceURL.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    sourceURL.stopAccessingSecurityScopedResource()
                }
            }

            let destinationURL = uniqueDestinationURL(for: sourceURL.lastPathComponent)

            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            importedCount += 1
        }

        return importedCount
    }

    private static func uniqueDestinationURL(for fileName: String) -> URL {
        let baseURL = importDirectory.appendingPathComponent(fileName)

        guard FileManager.default.fileExists(atPath: baseURL.path) else {
            return baseURL
        }

        let name = baseURL.deletingPathExtension().lastPathComponent
        let fileExtension = baseURL.pathExtension

        for index in 1...999 {
            let candidate = importDirectory.appendingPathComponent("\(name)-\(index)").appendingPathExtension(fileExtension)

            if !FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }

        return baseURL
    }
}

struct Genre: Identifiable {
    let id = UUID()
    let title: String
    let iconName: String
    let colors: [Color]
}
