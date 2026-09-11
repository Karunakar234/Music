import AVFoundation
import Observation
import SwiftUI

@Observable
final class StreamingPlayer {
    private(set) var currentTrack: Track?
    private(set) var isPlaying = false
    private(set) var errorMessage: String?
    var currentTime = 0.0
    var duration = 0.0

    private let player = AVPlayer()
    private var timeObserver: Any?

    init() {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self else {
                return
            }

            self.currentTime = time.seconds.isFinite ? time.seconds : 0
            let durationSeconds = self.player.currentItem?.duration.seconds ?? 0
            self.duration = durationSeconds.isFinite ? durationSeconds : 0
        }
    }

    func play(_ track: Track) {
        guard let streamURL = track.streamURL else {
            errorMessage = "No stream URL available for \(track.title)."
            currentTrack = track
            isPlaying = false
            currentTime = 0
            duration = 0
            return
        }

        errorMessage = nil
        currentTrack = track
        currentTime = 0
        duration = 0
        player.replaceCurrentItem(with: AVPlayerItem(url: streamURL))
        player.play()
        isPlaying = true
    }

    func togglePlayback() {
        if isPlaying {
            player.pause()
            isPlaying = false
        } else if currentTrack != nil {
            player.play()
            isPlaying = true
        }
    }

    func seek(by seconds: Double) {
        let currentSeconds = player.currentTime().seconds
        let durationSeconds = player.currentItem?.duration.seconds ?? 0
        let targetSeconds = max(0, min(currentSeconds + seconds, durationSeconds.isFinite ? durationSeconds : currentSeconds + seconds))
        let targetTime = CMTime(seconds: targetSeconds, preferredTimescale: 600)
        player.seek(to: targetTime)
    }

    func seek(to seconds: Double) {
        let boundedSeconds = max(0, min(seconds, duration > 0 ? duration : seconds))
        let targetTime = CMTime(seconds: boundedSeconds, preferredTimescale: 600)
        player.seek(to: targetTime)
        currentTime = boundedSeconds
    }

    func seekAndPlay(to seconds: Double) {
        seek(to: seconds)

        if currentTrack != nil {
            player.play()
            isPlaying = true
        }
    }

    func playPrevious(in tracks: [Track]) {
        guard let currentTrack, let currentIndex = tracks.firstIndex(where: { $0.id == currentTrack.id }) else {
            if let firstTrack = tracks.first {
                play(firstTrack)
            }
            return
        }

        let previousIndex = currentIndex == 0 ? tracks.count - 1 : currentIndex - 1
        play(tracks[previousIndex])
    }

    func playNext(in tracks: [Track]) {
        guard let currentTrack, let currentIndex = tracks.firstIndex(where: { $0.id == currentTrack.id }) else {
            if let firstTrack = tracks.first {
                play(firstTrack)
            }
            return
        }

        let nextIndex = currentIndex == tracks.count - 1 ? 0 : currentIndex + 1
        play(tracks[nextIndex])
    }

    func statusText(for track: Track) -> String {
        if let errorMessage, currentTrack?.id == track.id {
            return errorMessage
        }

        return track.artist
    }

    deinit {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
    }
}

struct NowPlayingSheet: View {
    let track: Track
    let tracks: [Track]
    let streamingPlayer: StreamingPlayer

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(colors: track.colors + [.black], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    Text("Now Playing")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white.opacity(0.82))

                    Spacer()

                    Image(systemName: "ellipsis")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                AlbumArtwork(colors: track.colors, iconName: track.iconName, size: 260)
                    .shadow(color: .black.opacity(0.35), radius: 24, y: 16)

                VStack(spacing: 8) {
                    Text(track.title)
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text(track.artist)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(1)
                }

                PlaybackTimeline(streamingPlayer: streamingPlayer, showsLabels: true)

                HStack(spacing: 24) {
                    playerControl(systemName: "gobackward.10", label: "Rewind 10 seconds") {
                        streamingPlayer.seek(by: -10)
                    }

                    playerControl(systemName: "backward.end.fill", label: "Previous song") {
                        streamingPlayer.playPrevious(in: tracks)
                    }

                    Button {
                        streamingPlayer.togglePlayback()
                    } label: {
                        Image(systemName: streamingPlayer.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(width: 76, height: 76)
                            .background(.white)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel(Text(streamingPlayer.isPlaying ? "Pause" : "Play"))

                    playerControl(systemName: "forward.end.fill", label: "Next song") {
                        streamingPlayer.playNext(in: tracks)
                    }

                    playerControl(systemName: "goforward.10", label: "Forward 10 seconds") {
                        streamingPlayer.seek(by: 10)
                    }
                }

                Spacer()
            }
            .padding(22)
        }
        .preferredColorScheme(.dark)
    }

    private func playerControl(systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(Color.black.opacity(0.24))
                .clipShape(Circle())
        }
        .accessibilityLabel(Text(label))
    }
}

struct PlaybackTimeline: View {
    let streamingPlayer: StreamingPlayer
    let showsLabels: Bool

    @State private var isEditing = false
    @State private var sliderValue = 0.0

    private var duration: Double {
        max(streamingPlayer.duration, 0)
    }

    private var currentValue: Binding<Double> {
        Binding(
            get: {
                isEditing ? sliderValue : min(streamingPlayer.currentTime, max(duration, 1))
            },
            set: { newValue in
                sliderValue = newValue
            }
        )
    }

    var body: some View {
        VStack(spacing: showsLabels ? 6 : 0) {
            GeometryReader { proxy in
                Slider(
                    value: currentValue,
                    in: 0...max(duration, 1),
                    onEditingChanged: { editing in
                        if editing {
                            sliderValue = streamingPlayer.currentTime
                        } else {
                            streamingPlayer.seekAndPlay(to: sliderValue)
                        }

                        isEditing = editing
                    }
                )
                .tint(.white)
                .disabled(duration <= 0)
                .contentShape(Rectangle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard duration > 0 else {
                                return
                            }

                            isEditing = true
                            sliderValue = seconds(for: value.location.x, width: proxy.size.width)
                        }
                        .onEnded { value in
                            guard duration > 0 else {
                                isEditing = false
                                return
                            }

                            let targetSeconds = seconds(for: value.location.x, width: proxy.size.width)
                            sliderValue = targetSeconds
                            streamingPlayer.seekAndPlay(to: targetSeconds)
                            isEditing = false
                        }
                )
            }
            .frame(height: 32)

            if showsLabels {
                HStack {
                    Text(formatTime(isEditing ? sliderValue : streamingPlayer.currentTime))
                    Spacer()
                    Text(formatTime(duration))
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
            }
        }
    }

    private func seconds(for xPosition: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else {
            return 0
        }

        let progress = min(max(Double(xPosition / width), 0), 1)
        return progress * duration
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds > 0 else {
            return "0:00"
        }

        let totalSeconds = Int(seconds.rounded())
        return "\(totalSeconds / 60):\(String(format: "%02d", totalSeconds % 60))"
    }
}
