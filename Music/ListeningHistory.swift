import SwiftUI

struct ListeningHistorySheet: View {
    let catalog: MusicCatalog
    let streamingPlayer: StreamingPlayer

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
                    LazyVStack(alignment: .leading, spacing: 16) {
                        if let currentTrack = streamingPlayer.currentTrack {
                            Text("Now playing")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)

                            LibraryRow(
                                artwork: AlbumArtwork(colors: currentTrack.colors, iconName: currentTrack.iconName, size: 56),
                                title: currentTrack.title,
                                subtitle: currentTrack.artist,
                                onTap: {
                                    streamingPlayer.play(currentTrack)
                                }
                            )
                        }

                        Text("Recently available")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.top, 8)

                        ForEach(catalog.tracks.prefix(50)) { track in
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
                    .padding(18)
                }
            }
            .navigationTitle("History")
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
}
