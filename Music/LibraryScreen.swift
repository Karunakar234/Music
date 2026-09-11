import SwiftUI

struct LibraryScreen: View {
    let catalog: MusicCatalog
    let streamingPlayer: StreamingPlayer
    let onImport: () -> Void

    @State private var selectedFilter = "All"

    private let filters = ["All", "Music", "Podcasts", "Playlists", "Artists", "Albums"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(LinearGradient(colors: [.mint, .green], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 34, height: 34)
                        .overlay(
                            Text("K")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.black)
                        )

                    Text("Your Library")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)

                    Spacer()

                    Button(action: onImport) {
                        Image(systemName: "plus")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                    }
                    .accessibilityLabel(Text("Import songs"))
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(filters, id: \.self) { filter in
                            Button {
                                selectedFilter = filter
                            } label: {
                                CategoryPill(title: filter, isSelected: selectedFilter == filter)
                            }
                        }
                    }
                }

                HStack(spacing: 12) {
                    LibraryStat(title: "Songs", value: "\(catalog.tracks.count)")
                    LibraryStat(title: "Podcasts", value: "\(catalog.podcasts.count)")
                    LibraryStat(title: "Playlists", value: "\(catalog.playlists.count)")
                }

                HStack(spacing: 12) {
                    Button(action: onImport) {
                        Label("Import", systemImage: "tray.and.arrow.down.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }

                    Button(action: onImport) {
                        Label("Load Files", systemImage: "folder.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(Color.white.opacity(0.13))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }

                HStack {
                    Label(selectedFilter, systemImage: "arrow.up.arrow.down")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.78))

                    Spacer()

                    Image(systemName: "square.grid.2x2")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.78))
                }

                LazyVStack(spacing: 16) {
                    libraryRows
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 150)
        }
    }

    @ViewBuilder
    private var libraryRows: some View {
        switch selectedFilter {
        case "Music":
            musicRows(Array(catalog.tracks.prefix(100)))
        case "Podcasts":
            podcastRows(catalog.podcasts)
        case "Playlists":
            playlistRows(catalog.playlists)
        case "Artists":
            artistRows(uniqueArtistTracks)
        case "Albums":
            albumRows(catalog.albums)
        default:
            LibraryRow(
                artwork: AlbumArtwork(colors: [.green, .mint], iconName: "pin.fill", size: 56),
                title: "Liked Songs",
                subtitle: "Pinned playlist - \(catalog.tracks.count) songs",
                onTap: {
                    playFirstTrack()
                }
            )

            musicRows(Array(catalog.tracks.prefix(12)))
            podcastRows(catalog.podcasts)
            playlistRows(catalog.playlists)
        }
    }

    private var uniqueArtistTracks: [Track] {
        var seenArtists = Set<String>()

        return catalog.tracks.filter { track in
            guard !seenArtists.contains(track.artist) else {
                return false
            }

            seenArtists.insert(track.artist)
            return true
        }
    }

    private func musicRows(_ tracks: [Track]) -> some View {
        ForEach(tracks) { track in
            LibraryRow(
                artwork: AlbumArtwork(colors: track.colors, iconName: track.iconName, size: 56),
                title: track.title,
                subtitle: track.artist,
                onTap: {
                    streamingPlayer.play(track)
                }
            )
        }
    }

    private func podcastRows(_ podcasts: [Podcast]) -> some View {
        ForEach(podcasts) { podcast in
            LibraryRow(
                artwork: AlbumArtwork(colors: podcast.colors, iconName: "waveform.circle.fill", size: 56),
                title: podcast.title,
                subtitle: "\(podcast.host) - Podcast"
            )
        }
    }

    private func playlistRows(_ playlists: [Playlist]) -> some View {
        ForEach(playlists) { playlist in
            LibraryRow(
                artwork: AlbumArtwork(colors: playlist.colors, iconName: playlist.iconName, size: 56),
                title: playlist.title,
                subtitle: "Playlist - tap to start",
                onTap: {
                    playFirstTrack()
                }
            )
        }
    }

    private func artistRows(_ tracks: [Track]) -> some View {
        ForEach(tracks) { track in
            LibraryRow(
                artwork: AlbumArtwork(colors: track.colors, iconName: "person.fill", size: 56),
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
            LibraryRow(
                artwork: AlbumArtwork(colors: album.colors, iconName: album.iconName, size: 56),
                title: album.title,
                subtitle: album.subtitle,
                onTap: {
                    playFirstTrack()
                }
            )
        }
    }

    private func playFirstTrack() {
        if let firstTrack = catalog.tracks.first {
            streamingPlayer.play(firstTrack)
        }
    }
}
