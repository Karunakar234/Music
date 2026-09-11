import AVFoundation
import Observation
#if canImport(ShazamKit)
import ShazamKit
#endif
import SwiftUI

@Observable
final class SongRecognitionManager {
    private(set) var isListening = false
    private(set) var title: String?
    private(set) var artist: String?
    private(set) var message = "Tap listen and hold your phone near the song."
    private(set) var webURL: URL?

    #if canImport(ShazamKit)
    private var recognitionTask: Task<Void, Never>?
    #endif

    @MainActor
    func startListening() {
        title = nil
        artist = nil
        webURL = nil

        guard !Self.isRunningInPreview else {
            title = "Preview Song"
            artist = "Preview Artist"
            message = "Song recognition is disabled in Xcode previews."
            return
        }

        guard Self.hasMicrophoneUsageDescription else {
            message = "Add NSMicrophoneUsageDescription in the target Info settings before using song recognition."
            return
        }

        #if canImport(ShazamKit)
        if #available(iOS 16.0, macOS 13.0, *) {
            isListening = true
            message = "Listening..."

            recognitionTask?.cancel()
            recognitionTask = Task {
                let session = SHManagedSession()
                let result = await session.result()

                await MainActor.run {
                    self.isListening = false

                    switch result {
                    case .match(let match):
                        guard let item = match.mediaItems.first else {
                            self.message = "Matched audio, but no song details were returned."
                            return
                        }

                        self.title = item.title ?? "Unknown Song"
                        self.artist = item.artist ?? "Unknown Artist"
                        self.webURL = item.webURL
                        self.message = "Song found"
                    case .noMatch:
                        self.message = "No match found. Try again closer to the speaker."
                    case .error(let error, _):
                        self.message = "Recognition failed: \(error.localizedDescription)"
                    @unknown default:
                        self.message = "Recognition finished with an unknown result."
                    }
                }
            }
        } else {
            message = "Song recognition needs a newer OS version."
        }
        #else
        message = "ShazamKit is not available on this run destination."
        #endif
    }

    private static var isRunningInPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    private static var hasMicrophoneUsageDescription: Bool {
        Bundle.main.object(forInfoDictionaryKey: "NSMicrophoneUsageDescription") != nil
    }
}

struct SongIdentifierSheet: View {
    let songRecognizer: SongRecognitionManager

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

                VStack(spacing: 28) {
                    Spacer(minLength: 12)

                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(songRecognizer.isListening ? 0.3 : 0.14))
                            .frame(width: songRecognizer.isListening ? 190 : 160, height: songRecognizer.isListening ? 190 : 160)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: songRecognizer.isListening)

                        Button {
                            songRecognizer.startListening()
                        } label: {
                            Image(systemName: songRecognizer.isListening ? "waveform" : "waveform.badge.magnifyingglass")
                                .font(.system(size: 54, weight: .bold))
                                .foregroundStyle(.black)
                                .frame(width: 126, height: 126)
                                .background(Color.green)
                                .clipShape(Circle())
                        }
                        .disabled(songRecognizer.isListening)
                        .accessibilityLabel(Text("Listen and identify song"))
                    }

                    VStack(spacing: 10) {
                        Text(songRecognizer.isListening ? "Listening" : "Identify Song")
                            .font(.title.weight(.bold))
                            .foregroundStyle(.white)

                        Text(songRecognizer.message)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.68))
                            .multilineTextAlignment(.center)
                    }

                    if let title = songRecognizer.title {
                        VStack(spacing: 12) {
                            AlbumArtwork(colors: [.green, .teal], iconName: "music.note", size: 76)

                            Text(title)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)

                            Text(songRecognizer.artist ?? "Unknown Artist")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.68))

                            if let webURL = songRecognizer.webURL {
                                Link(destination: webURL) {
                                    Label("Open in Shazam", systemImage: "safari.fill")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, 16)
                                        .frame(height: 42)
                                        .background(Color.green)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }

                    Spacer()
                }
                .padding(18)
            }
            .navigationTitle("Find Song")
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

