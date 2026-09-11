import SwiftUI

struct SettingsSheet: View {
    let catalog: MusicCatalog
    let currentTrack: Track?
    let importMessage: String?
    let onImport: () -> Void
    let onReload: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.08, green: 0.10, blue: 0.09), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        sourceSection
                        librarySection
                        playbackSection
                        actionsSection
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.green)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var sourceSection: some View {
        SettingsGroup(title: "Source") {
            SettingsInfoRow(iconName: "folder.fill", title: "Library", value: catalog.sourceMessage)

            if let importMessage {
                SettingsInfoRow(iconName: "checkmark.circle.fill", title: "Last action", value: importMessage)
            }
        }
    }

    private var librarySection: some View {
        SettingsGroup(title: "Catalog") {
            SettingsInfoRow(iconName: "music.note.list", title: "Songs", value: "\(catalog.tracks.count)")
            SettingsInfoRow(iconName: "rectangle.stack.fill", title: "Playlists", value: "\(catalog.playlists.count)")
            SettingsInfoRow(iconName: "waveform.circle.fill", title: "Podcasts", value: "\(catalog.podcasts.count)")
        }
    }

    private var playbackSection: some View {
        SettingsGroup(title: "Playback") {
            SettingsInfoRow(
                iconName: "play.circle.fill",
                title: "Now playing",
                value: currentTrack.map { "\($0.title) - \($0.artist)" } ?? "Nothing playing"
            )
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(action: onImport) {
                Label("Load Audio Files", systemImage: "tray.and.arrow.down.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            Button(action: onReload) {
                Label("Reload Library", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }
}

struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)

            VStack(spacing: 1) {
                content
            }
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

struct SettingsInfoRow: View {
    let iconName: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.headline)
                .foregroundStyle(.green)
                .frame(width: 28)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            Spacer()

            Text(value)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.64))
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(12)
    }
}
