import AVFAudio
import AVFoundation
import Observation
#if canImport(ShazamKit)
import ShazamKit
#endif
import SwiftUI

enum SongRecognitionStatus {
    case idle
    case listening
    case matched
    case noMatch
    case failed
    case unavailable
    case permissionDenied
}

@Observable
final class SongRecognitionManager {
    private(set) var status: SongRecognitionStatus = .idle
    private(set) var elapsedSeconds = 0
    private(set) var title: String?
    private(set) var artist: String?
    private(set) var artworkURL: URL?
    private(set) var genres: [String] = []
    private(set) var confidence: Float?
    private(set) var message = "Tap listen and hold your phone near the song."
    private(set) var webURL: URL?

    private var recognitionTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?

    let listeningLimit = 12

    var isListening: Bool {
        status == .listening
    }

    var listeningProgress: Double {
        guard listeningLimit > 0 else {
            return 0
        }

        return min(Double(elapsedSeconds) / Double(listeningLimit), 1)
    }

    @MainActor
    func startListening() {
        guard !isListening else {
            return
        }

        resetResult()

        guard !Self.isRunningInPreview else {
            title = "Preview Song"
            artist = "Preview Artist"
            genres = ["Preview"]
            confidence = 0.96
            status = .matched
            message = "Song recognition is disabled in Xcode previews."
            return
        }

        guard Self.hasMicrophoneUsageDescription else {
            status = .unavailable
            message = "Add NSMicrophoneUsageDescription in the target Info settings before using song recognition."
            return
        }

        status = .listening
        message = "Listening for the strongest part of the song..."
        startListeningTimer()

        recognitionTask?.cancel()
        recognitionTask = Task { [weak self] in
            let hasMicrophoneAccess = await Self.requestMicrophoneAccess()

            guard !Task.isCancelled else {
                return
            }

            guard hasMicrophoneAccess else {
                await MainActor.run {
                    self?.finishListening(status: .permissionDenied, message: "Microphone access is off. Enable it in Settings to identify songs.")
                }
                return
            }

        #if canImport(ShazamKit)
            if #available(iOS 16.0, macOS 13.0, *) {
                let session = SHManagedSession()
                let result = await session.result()

                await MainActor.run {
                    self?.handleRecognitionResult(result)
                }
            } else {
                await MainActor.run {
                    self?.finishListening(status: .unavailable, message: "Song recognition needs a newer OS version.")
                }
            }
        #else
            await MainActor.run {
                self?.finishListening(status: .unavailable, message: "ShazamKit is not available on this run destination.")
            }
        #endif
        }
    }

    @MainActor
    func stopListening() {
        guard isListening else {
            return
        }

        recognitionTask?.cancel()
        finishListening(status: .idle, message: "Listening stopped. Tap listen when the song is clear.")
    }

    private func resetResult() {
        elapsedSeconds = 0
        title = nil
        artist = nil
        artworkURL = nil
        genres = []
        confidence = nil
        webURL = nil
    }

    @MainActor
    private func startListeningTimer() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)

                await MainActor.run {
                    guard let self, self.isListening else {
                        return
                    }

                    self.elapsedSeconds += 1

                    if self.elapsedSeconds >= self.listeningLimit {
                        self.recognitionTask?.cancel()
                        self.finishListening(status: .noMatch, message: "No match found. Try again closer to the speaker.")
                    } else {
                        self.message = self.listeningMessage
                    }
                }
            }
        }
    }

    private var listeningMessage: String {
        let remainingSeconds = max(listeningLimit - elapsedSeconds, 0)
        return "Keep the microphone near the song for \(remainingSeconds) more seconds."
    }

    @MainActor
    private func finishListening(status: SongRecognitionStatus, message: String) {
        self.status = status
        self.message = message
        timerTask?.cancel()
        timerTask = nil
    }

    #if canImport(ShazamKit)
    @available(iOS 16.0, macOS 13.0, *)
    @MainActor
    private func handleRecognitionResult(_ result: SHSession.Result) {
        guard isListening else {
            return
        }

        switch result {
        case .match(let match):
            guard let item = match.mediaItems.first else {
                finishListening(status: .failed, message: "Matched audio, but no song details were returned.")
                return
            }

            title = item.title ?? "Unknown Song"
            artist = item.artist ?? "Unknown Artist"
            artworkURL = item.artworkURL
            genres = item.genres
            confidence = item.confidence
            webURL = item.webURL
            finishListening(status: .matched, message: "Song found")
        case .noMatch:
            finishListening(status: .noMatch, message: "No match found. Try again closer to the speaker.")
        case .error(let error, _):
            finishListening(status: .failed, message: "Recognition failed: \(error.localizedDescription)")
        @unknown default:
            finishListening(status: .failed, message: "Recognition finished with an unknown result.")
        }
    }
    #endif

    private static func requestMicrophoneAccess() async -> Bool {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, visionOS 1.0, *) {
            return await AVAudioApplication.requestRecordPermission()
        }

        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { isGranted in
                continuation.resume(returning: isGranted)
            }
        }
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

    private var statusIconName: String {
        switch songRecognizer.status {
        case .idle:
            return "waveform.badge.magnifyingglass"
        case .listening:
            return "waveform"
        case .matched:
            return "checkmark.circle.fill"
        case .noMatch:
            return "questionmark.circle.fill"
        case .failed, .unavailable:
            return "exclamationmark.triangle.fill"
        case .permissionDenied:
            return "mic.slash.fill"
        }
    }

    private var statusTitle: String {
        switch songRecognizer.status {
        case .idle:
            return "Identify Song"
        case .listening:
            return "Listening"
        case .matched:
            return "Match Found"
        case .noMatch:
            return "Try Again"
        case .failed:
            return "Recognition Failed"
        case .unavailable:
            return "Setup Needed"
        case .permissionDenied:
            return "Mic Access Needed"
        }
    }

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

                    recognitionButton

                    VStack(spacing: 10) {
                        Text(statusTitle)
                            .font(.title.weight(.bold))
                            .foregroundStyle(.white)

                        Text(songRecognizer.message)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.68))
                            .multilineTextAlignment(.center)
                    }

                    if songRecognizer.isListening {
                        listeningStatus
                    } else if songRecognizer.title != nil {
                        matchCard
                    } else {
                        listeningTips
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

    private var recognitionButton: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 8)
                .frame(width: 178, height: 178)

            Circle()
                .trim(from: 0, to: songRecognizer.isListening ? songRecognizer.listeningProgress : 1)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 178, height: 178)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.25), value: songRecognizer.listeningProgress)

            Circle()
                .fill(Color.green.opacity(songRecognizer.isListening ? 0.26 : 0.14))
                .frame(width: songRecognizer.isListening ? 156 : 140, height: songRecognizer.isListening ? 156 : 140)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: songRecognizer.isListening)

            Button {
                if songRecognizer.isListening {
                    songRecognizer.stopListening()
                } else {
                    songRecognizer.startListening()
                }
            } label: {
                Image(systemName: songRecognizer.isListening ? "stop.fill" : statusIconName)
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 118, height: 118)
                    .background(Color.green)
                    .clipShape(Circle())
            }
            .accessibilityLabel(Text(songRecognizer.isListening ? "Stop listening" : "Listen and identify song"))
        }
        .frame(width: 190, height: 190)
    }

    private var listeningStatus: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "mic.fill")
                    .foregroundStyle(.green)

                Text("\(max(songRecognizer.listeningLimit - songRecognizer.elapsedSeconds, 0))s remaining")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }

            Text("Try a louder section with vocals or a steady beat.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.62))
                .multilineTextAlignment(.center)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var matchCard: some View {
        VStack(spacing: 14) {
            artwork

            VStack(spacing: 5) {
                Text(songRecognizer.title ?? "Unknown Song")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(songRecognizer.artist ?? "Unknown Artist")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.68))
            }

            if !songRecognizer.genres.isEmpty || songRecognizer.confidence != nil {
                HStack(spacing: 8) {
                    if let genre = songRecognizer.genres.first {
                        SongRecognitionChip(title: genre, systemImage: "music.quarternote.3")
                    }

                    if let confidence = songRecognizer.confidence {
                        SongRecognitionChip(title: "\(Int(confidence * 100))% match", systemImage: "checkmark.seal.fill")
                    }
                }
            }

            HStack(spacing: 10) {
                Button {
                    songRecognizer.startListening()
                } label: {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                if let webURL = songRecognizer.webURL {
                    Link(destination: webURL) {
                        Label("Open", systemImage: "safari.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private var artwork: some View {
        if let artworkURL = songRecognizer.artworkURL {
            AsyncImage(url: artworkURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    AlbumArtwork(colors: [.green, .teal], iconName: "music.note", size: 92)
                }
            }
            .frame(width: 92, height: 92)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            AlbumArtwork(colors: [.green, .teal], iconName: "music.note", size: 92)
        }
    }

    private var listeningTips: some View {
        VStack(alignment: .leading, spacing: 12) {
            SongRecognitionTip(systemImage: "speaker.wave.2.fill", title: "Move closer to the sound")
            SongRecognitionTip(systemImage: "waveform.path", title: "Use a clear chorus or beat")
            SongRecognitionTip(systemImage: "mic.fill", title: "Keep background noise low")
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct SongRecognitionChip: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.82))
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(Color.white.opacity(0.1))
            .clipShape(Capsule())
    }
}

struct SongRecognitionTip: View {
    let systemImage: String
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.green)
                .frame(width: 22)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.82))
        }
    }
}
