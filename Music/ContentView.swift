//
//  ContentView.swift
//  Music
//
//  Created by Karunakar Katraju on 9/10/26.
//

import AVFoundation
import Observation
#if canImport(ShazamKit)
import ShazamKit
#endif
import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @State private var streamingPlayer = StreamingPlayer()
    @State private var songRecognizer = SongRecognitionManager()
    @State private var notificationManager = NotificationManager()
    @State private var catalog = MusicCatalog.local
    @State private var isImporterPresented = false
    @State private var isHistoryPresented = false
    @State private var isNotificationsPresented = false
    @State private var isNowPlayingPresented = false
    @State private var isSongIdentifierPresented = false
    @State private var isSettingsPresented = false
    @State private var importMessage: String?

    init() {
        _catalog = State(initialValue: .local)
    }

    fileprivate init(catalog: MusicCatalog) {
        _catalog = State(initialValue: catalog)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(red: 0.07, green: 0.10, blue: 0.08), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            activeScreen

            VStack(spacing: 0) {
                miniPlayer
                tabBar
            }
        }
        .preferredColorScheme(.dark)
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: true,
            onCompletion: handleImportResult
        )
        .sheet(isPresented: $isNotificationsPresented) {
            NotificationsSheet(notificationManager: notificationManager)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isHistoryPresented) {
            ListeningHistorySheet(catalog: catalog, streamingPlayer: streamingPlayer)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isNowPlayingPresented) {
            if let track = streamingPlayer.currentTrack ?? catalog.tracks.first {
                NowPlayingSheet(track: track, tracks: catalog.tracks, streamingPlayer: streamingPlayer)
                    .presentationDetents([.large])
            }
        }
        .sheet(isPresented: $isSongIdentifierPresented) {
            SongIdentifierSheet(songRecognizer: songRecognizer)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsSheet(
                catalog: catalog,
                currentTrack: streamingPlayer.currentTrack,
                importMessage: importMessage,
                onImport: {
                    isSettingsPresented = false
                    isImporterPresented = true
                },
                onReload: {
                    catalog = MusicCatalog.local
                    importMessage = "Library reloaded"
                }
            )
            .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    private var activeScreen: some View {
        switch selectedTab {
        case .home:
            homeScreen
        case .search:
            SearchScreen(
                catalog: catalog,
                streamingPlayer: streamingPlayer,
                onIdentifySong: {
                    isSongIdentifierPresented = true
                }
            )
        case .library:
            LibraryScreen(
                catalog: catalog,
                streamingPlayer: streamingPlayer,
                onImport: {
                    isImporterPresented = true
                }
            )
        }
    }

    private var homeScreen: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 26) {
                header
                localSongStatus
                identifySongButton
                categorySelector
                playlistGrid
                albumSection
                trackSection
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 150)
        }
    }

    private var localSongStatus: some View {
        HStack(spacing: 10) {
            Label(importMessage ?? catalog.sourceMessage, systemImage: catalog.usesLocalTracks ? "checkmark.circle.fill" : "folder")
                .font(.caption.weight(.semibold))
                .foregroundStyle(catalog.usesLocalTracks ? .green : .white.opacity(0.68))
                .lineLimit(1)

            Spacer()

            Button {
                isImporterPresented = true
            } label: {
                Label("Load", systemImage: "tray.and.arrow.down.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(Color.green)
                    .clipShape(Capsule())
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, 4)
        .frame(height: 38)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var identifySongButton: some View {
        Button {
            isSongIdentifierPresented = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "waveform.badge.magnifyingglass")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(width: 40, height: 40)
                    .background(Color.green)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("Identify Song")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Listen nearby and find the song title")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.68))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .padding(12)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            do {
                let importedCount = try ImportedSongStore.importFiles(from: urls)
                catalog = MusicCatalog.local
                importMessage = importedCount == 1 ? "Imported 1 song" : "Imported \(importedCount) songs"
            } catch {
                importMessage = "Import failed: \(error.localizedDescription)"
            }
        case .failure(let error):
            importMessage = "Import failed: \(error.localizedDescription)"
        }
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

            headerButton(systemName: "bell") {
                isNotificationsPresented = true
            }
            headerButton(systemName: "clock") {
                isHistoryPresented = true
            }
            headerButton(systemName: "gearshape") {
                isSettingsPresented = true
            }
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
            ForEach(catalog.playlists) { playlist in
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
                    ForEach(catalog.albums) { album in
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

            LazyVStack(spacing: 14) {
                ForEach(catalog.tracks) { track in
                    TrackRow(
                        track: track,
                        isPlaying: streamingPlayer.currentTrack?.id == track.id && streamingPlayer.isPlaying,
                        onPlay: {
                            streamingPlayer.play(track)
                        }
                    )
                }
            }
        }
    }

    private var miniPlayer: some View {
        Group {
            if let displayTrack = streamingPlayer.currentTrack ?? catalog.tracks.first {
                VStack(spacing: 6) {
                    Button {
                        isNowPlayingPresented = true
                    } label: {
                        HStack(spacing: 12) {
                            AlbumArtwork(colors: displayTrack.colors, iconName: displayTrack.iconName, size: 46)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(displayTrack.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Text(streamingPlayer.statusText(for: displayTrack))
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.72))
                                    .lineLimit(1)
                            }

                            Spacer()

                            Image(systemName: "hifispeaker.2")
                                .font(.system(size: 19, weight: .medium))
                                .foregroundStyle(.white.opacity(0.86))

                            Button {
                                streamingPlayer.togglePlayback()
                            } label: {
                                Image(systemName: streamingPlayer.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 36, height: 36)
                            }
                            .accessibilityLabel(Text(streamingPlayer.isPlaying ? "Pause" : "Play"))
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Open now playing"))

                    PlaybackTimeline(streamingPlayer: streamingPlayer, showsLabels: false)
                }
            }
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
            TabBarItem(tab: .home, selectedTab: $selectedTab)
            TabBarItem(tab: .search, selectedTab: $selectedTab)
            TabBarItem(tab: .library, selectedTab: $selectedTab)
        }
        .padding(.top, 10)
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
        .background(.black.opacity(0.94))
    }

    private func headerButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
        }
        .accessibilityLabel(Text(systemName))
    }
}

#Preview {
    ContentView(catalog: .preview)
}
