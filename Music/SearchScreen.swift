import SwiftUI

struct SearchScreen: View {
    @State private var searchText = ""
    @State private var selectedQuickAction = "All"

    let catalog: MusicCatalog
    let streamingPlayer: StreamingPlayer
    let onIdentifySong: () -> Void

    private let quickActions = ["All", "Songs", "Artists", "Albums", "Playlists"]

    private var trendingSearches: [String] {
        Array(catalog.tracks.prefix(4).map(\.title))
    }

    private var query: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSearching: Bool {
        !query.isEmpty
    }

    private var filteredGenres: [Genre] {
        guard isSearching else {
            return catalog.genres
        }

        return catalog.genres.filter { genre in
            genre.title.localizedCaseInsensitiveContains(query)
        }
    }

    private var filteredTracks: [Track] {
        catalog.tracks.filter { track in
            track.title.localizedCaseInsensitiveContains(query) ||
            track.artist.localizedCaseInsensitiveContains(query)
        }
    }

    private var filteredAlbums: [Album] {
        catalog.albums.filter { album in
            album.title.localizedCaseInsensitiveContains(query) ||
            album.subtitle.localizedCaseInsensitiveContains(query)
        }
    }

    private var filteredPlaylists: [Playlist] {
        catalog.playlists.filter { playlist in
            playlist.title.localizedCaseInsensitiveContains(query)
        }
    }

    private var filteredArtists: [Track] {
        var seenArtists = Set<String>()

        return catalog.tracks.filter { track in
            let matches = track.artist.localizedCaseInsensitiveContains(query) ||
            track.title.localizedCaseInsensitiveContains(query)

            guard matches && !seenArtists.contains(track.artist) else {
                return false
            }

            seenArtists.insert(track.artist)
            return true
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Text("Search")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)

                    Spacer()

                    Button(action: onIdentifySong) {
                        Image(systemName: "camera.viewfinder")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                    }
                    .accessibilityLabel(Text("Listen and identify song"))
                }

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.black.opacity(0.72))

                    TextField("What do you want to listen to?", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .foregroundStyle(.black)
                        .submitLabel(.search)

                    if isSearching {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.black.opacity(0.45))
                        }
                        .accessibilityLabel(Text("Clear search"))
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(quickActions, id: \.self) { action in
                            Button {
                                selectedQuickAction = action
                            } label: {
                                Text(action)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(selectedQuickAction == action ? .black : .white)
                                    .padding(.horizontal, 15)
                                    .frame(height: 34)
                                    .background(selectedQuickAction == action ? Color.green : Color.white.opacity(0.13))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                SearchHero {
                    playFirstTrack()
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Trending now")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)

                    VStack(spacing: 12) {
                        ForEach(trendingSearches, id: \.self) { search in
                            Button {
                                searchText = search
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.up.right")
                                        .font(.callout.weight(.bold))
                                        .foregroundStyle(.green)
                                        .frame(width: 30, height: 30)
                                        .background(Color.white.opacity(0.1))
                                        .clipShape(Circle())

                                    Text(search)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)

                                    Spacer()
                                }
                            }
                        }
                    }
                }

                if isSearching {
                    searchResults
                } else {
                    Text("Browse all")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(filteredGenres) { genre in
                            Button {
                                searchText = genre.title
                            } label: {
                                GenreTile(genre: genre)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 150)
        }
    }

    @ViewBuilder
    private var searchResults: some View {
        let resultCount = resultCount(for: selectedQuickAction)

        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("\(selectedQuickAction) results")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Spacer()

                Text("\(resultCount)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.green)
            }

            if resultCount == 0 {
                ContentUnavailableSearchView(query: query)
            } else {
                LazyVStack(spacing: 14) {
                    resultRows(for: selectedQuickAction)
                }
            }
        }
    }

    @ViewBuilder
    private func resultRows(for action: String) -> some View {
        switch action {
        case "All":
            resultSection(title: "Songs", count: filteredTracks.count) {
                songRows(Array(filteredTracks.prefix(25)))
            }

            resultSection(title: "Artists", count: filteredArtists.count) {
                artistRows(Array(filteredArtists.prefix(8)))
            }

            resultSection(title: "Playlists", count: filteredPlaylists.count) {
                playlistRows(filteredPlaylists)
            }
        case "Artists":
            artistRows(filteredArtists)
        case "Albums":
            albumRows(filteredAlbums)
        case "Playlists":
            playlistRows(filteredPlaylists)
        default:
            songRows(filteredTracks)
        }
    }

    private func resultSection<Content: View>(title: String, count: Int, @ViewBuilder content: () -> Content) -> some View {
        Group {
            if count > 0 {
                VStack(alignment: .leading, spacing: 12) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)

                    content()
                }
            }
        }
    }

    private func songRows(_ tracks: [Track]) -> some View {
        ForEach(tracks) { track in
            SearchResultRow(
                artwork: AlbumArtwork(colors: track.colors, iconName: track.iconName, size: 50),
                title: track.title,
                subtitle: track.artist,
                onTap: {
                    streamingPlayer.play(track)
                }
            )
        }
    }

    private func artistRows(_ tracks: [Track]) -> some View {
        ForEach(tracks) { track in
            SearchResultRow(
                artwork: AlbumArtwork(colors: track.colors, iconName: "person.fill", size: 50),
                title: track.artist,
                subtitle: "Artist - tap to play \(track.title)",
                onTap: {
                    streamingPlayer.play(track)
                }
            )
        }
    }

    private func albumRows(_ albums: [Album]) -> some View {
        ForEach(albums) { album in
            SearchResultRow(
                artwork: AlbumArtwork(colors: album.colors, iconName: album.iconName, size: 50),
                title: album.title,
                subtitle: album.subtitle,
                onTap: {
                    playFirstTrack()
                }
            )
        }
    }

    private func playlistRows(_ playlists: [Playlist]) -> some View {
        ForEach(playlists) { playlist in
            SearchResultRow(
                artwork: AlbumArtwork(colors: playlist.colors, iconName: playlist.iconName, size: 50),
                title: playlist.title,
                subtitle: "Playlist - tap to start",
                onTap: {
                    playFirstTrack()
                }
            )
        }
    }

    private func resultCount(for action: String) -> Int {
        switch action {
        case "All":
            filteredTracks.count + filteredArtists.count + filteredAlbums.count + filteredPlaylists.count
        case "Artists":
            filteredArtists.count
        case "Albums":
            filteredAlbums.count
        case "Playlists":
            filteredPlaylists.count
        default:
            filteredTracks.count
        }
    }

    private func playFirstTrack() {
        if let firstTrack = catalog.tracks.first {
            streamingPlayer.play(firstTrack)
        }
    }
}
