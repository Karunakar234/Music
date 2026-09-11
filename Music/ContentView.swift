//
//  ContentView.swift
//  Music
//
//  Created by Karunakar Katraju on 9/10/26.
//

import SwiftUI

struct ContentView: View {
    private let playlists = Playlist.sample
    private let featuredAlbums = Album.sample
    private let recentTracks = Track.sample

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(red: 0.07, green: 0.10, blue: 0.08), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    header
                    categorySelector
                    playlistGrid
                    albumSection
                    trackSection
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 150)
            }

            VStack(spacing: 0) {
                miniPlayer
                tabBar
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(LinearGradient(colors: [.mint, .green], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 38, height: 38)
                .overlay(
                    Text("K")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.black)
                )

            Text("Good evening")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            Spacer()

            headerButton(systemName: "bell")
            headerButton(systemName: "clock")
            headerButton(systemName: "gearshape")
        }
    }

    private var categorySelector: some View {
        HStack(spacing: 10) {
            CategoryPill(title: "All", isSelected: true)
            CategoryPill(title: "Music", isSelected: false)
            CategoryPill(title: "Podcasts", isSelected: false)
        }
    }

    private var playlistGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(playlists) { playlist in
                PlaylistTile(playlist: playlist)
            }
        }
    }

    private var albumSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Made for you")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(featuredAlbums) { album in
                        AlbumCard(album: album)
                    }
                }
            }
        }
    }

    private var trackSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recently played")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            VStack(spacing: 14) {
                ForEach(recentTracks) { track in
                    TrackRow(track: track)
                }
            }
        }
    }

    private var miniPlayer: some View {
        HStack(spacing: 12) {
            AlbumArtwork(colors: [.green, .teal], iconName: "waveform", size: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text("After Hours")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("The Weeknd")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "hifispeaker.2")
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(.white.opacity(0.86))

            Image(systemName: "play.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color(red: 0.18, green: 0.33, blue: 0.27))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
    }

    private var tabBar: some View {
        HStack {
            TabBarItem(title: "Home", systemName: "house.fill", isSelected: true)
            TabBarItem(title: "Search", systemName: "magnifyingglass", isSelected: false)
            TabBarItem(title: "Library", systemName: "books.vertical.fill", isSelected: false)
        }
        .padding(.top, 10)
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
        .background(.black.opacity(0.94))
    }

    private func headerButton(systemName: String) -> some View {
        Button(action: {}) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
        }
        .accessibilityLabel(Text(systemName))
    }
}

private struct CategoryPill: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? .black : .white)
            .padding(.horizontal, 16)
            .frame(height: 34)
            .background(isSelected ? Color.green : Color.white.opacity(0.13))
            .clipShape(Capsule())
    }
}

private struct PlaylistTile: View {
    let playlist: Playlist

    var body: some View {
        HStack(spacing: 10) {
            AlbumArtwork(colors: playlist.colors, iconName: playlist.iconName, size: 58)

            Text(playlist.title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 0)
        }
        .frame(height: 58)
        .background(Color.white.opacity(0.11))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

private struct AlbumCard: View {
    let album: Album

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            AlbumArtwork(colors: album.colors, iconName: album.iconName, size: 138)

            Text(album.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .frame(width: 138, alignment: .leading)

            Text(album.subtitle)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.64))
                .lineLimit(2)
                .frame(width: 138, alignment: .leading)
        }
        .frame(width: 138, alignment: .leading)
    }
}

private struct TrackRow: View {
    let track: Track

    var body: some View {
        HStack(spacing: 12) {
            AlbumArtwork(colors: track.colors, iconName: track.iconName, size: 50)

            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(track.artist)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel(Text("More options"))
        }
    }
}

private struct TabBarItem: View {
    let title: String
    let systemName: String
    let isSelected: Bool

    var body: some View {
        Button(action: {}) {
            VStack(spacing: 5) {
                Image(systemName: systemName)
                    .font(.system(size: 22, weight: .semibold))
                Text(title)
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.55))
            .frame(maxWidth: .infinity)
        }
        .accessibilityLabel(Text(title))
    }
}

private struct AlbumArtwork: View {
    let colors: [Color]
    let iconName: String
    let size: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: iconName)
                    .font(.system(size: size * 0.34, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
            )
    }
}

private struct Playlist: Identifiable {
    let id = UUID()
    let title: String
    let iconName: String
    let colors: [Color]

    static let sample = [
        Playlist(title: "Liked Songs", iconName: "heart.fill", colors: [.purple, .blue]),
        Playlist(title: "Daily Mix 1", iconName: "music.note", colors: [.orange, .pink]),
        Playlist(title: "Discover Weekly", iconName: "sparkles", colors: [.green, .mint]),
        Playlist(title: "Chill Hits", iconName: "moon.stars.fill", colors: [.indigo, .cyan]),
        Playlist(title: "Top Artists", iconName: "person.2.fill", colors: [.red, .orange]),
        Playlist(title: "Release Radar", iconName: "dot.radiowaves.left.and.right", colors: [.teal, .blue])
    ]
}

private struct Album: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let iconName: String
    let colors: [Color]

    static let sample = [
        Album(title: "Late Night Drive", subtitle: "Synth pop and neon favorites", iconName: "car.fill", colors: [.pink, .purple]),
        Album(title: "Focus Flow", subtitle: "Instrumentals for deep work", iconName: "brain.head.profile", colors: [.blue, .teal]),
        Album(title: "Fresh Finds", subtitle: "New songs picked for you", iconName: "leaf.fill", colors: [.green, .yellow]),
        Album(title: "Acoustic Morning", subtitle: "Soft songs to start slow", iconName: "guitars.fill", colors: [.brown, .orange])
    ]
}

private struct Track: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let iconName: String
    let colors: [Color]

    static let sample = [
        Track(title: "Blinding Lights", artist: "The Weeknd", iconName: "sun.max.fill", colors: [.red, .orange]),
        Track(title: "Levitating", artist: "Dua Lipa", iconName: "sparkle", colors: [.purple, .pink]),
        Track(title: "As It Was", artist: "Harry Styles", iconName: "circle.grid.cross.fill", colors: [.cyan, .blue]),
        Track(title: "Anti-Hero", artist: "Taylor Swift", iconName: "star.fill", colors: [.indigo, .mint])
    ]
}

#Preview {
    ContentView()
}
