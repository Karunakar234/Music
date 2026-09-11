import SwiftUI

struct CategoryPill: View {
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

struct PlaylistTile: View {
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

struct AlbumCard: View {
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

struct TrackRow: View {
    let track: Track
    let isPlaying: Bool
    let onPlay: () -> Void

    var body: some View {
        Button(action: onPlay) {
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

                Image(systemName: isPlaying ? "speaker.wave.2.fill" : "play.circle.fill")
                    .font(.title3)
                    .foregroundStyle(isPlaying ? .green : .white.opacity(0.8))
                    .frame(width: 32, height: 32)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Play \(track.title) by \(track.artist)"))
    }
}
struct SearchResultRow<Artwork: View>: View {
    let artwork: Artwork
    let title: String
    let subtitle: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                artwork

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
            }
        }
        .buttonStyle(.plain)
    }
}

struct ContentUnavailableSearchView: View {
    let query: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white.opacity(0.6))

            Text("No results for \"\(query)\"")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)

            Text("Try another song, artist, album, or playlist.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.62))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct SearchHero: View {
    let onPlay: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            AlbumArtwork(colors: [.pink, .orange], iconName: "sparkles", size: 72)

            VStack(alignment: .leading, spacing: 6) {
                Text("Instant mix")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text("Search a song, artist, or mood and start a fresh station.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(2)
            }

            Spacer()

            Button(action: onPlay) {
                Image(systemName: "play.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(width: 42, height: 42)
                    .background(Color.green)
                    .clipShape(Circle())
            }
            .accessibilityLabel(Text("Start instant mix"))
        }
        .padding(14)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct LibraryStat: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct GenreTile: View {
    let genre: Genre

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(LinearGradient(colors: genre.colors, startPoint: .topLeading, endPoint: .bottomTrailing))

            Image(systemName: genre.iconName)
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(.white.opacity(0.34))
                .rotationEffect(.degrees(15))
                .offset(x: 48, y: -10)

            Text(genre.title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .padding(12)
        }
        .frame(height: 104)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct LibraryRow<Artwork: View>: View {
    let artwork: Artwork
    let title: String
    let subtitle: String
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                artwork

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(1)
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

struct TabBarItem: View {
    let tab: AppTab
    @Binding var selectedTab: AppTab

    private var isSelected: Bool {
        selectedTab == tab
    }

    var body: some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 5) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 22, weight: .semibold))
                Text(tab.rawValue)
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.55))
            .frame(maxWidth: .infinity)
        }
        .accessibilityLabel(Text(tab.rawValue))
    }
}

struct AlbumArtwork: View {
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
