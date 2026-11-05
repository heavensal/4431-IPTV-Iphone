import SwiftUI
import MobileVLCKit
import AVFAudio
import ActivityKit

@MainActor final class Playback: ObservableObject {
    let engine = VLCMediaPlayer()
    @Published var title = ""
    @Published var active = false
    @Published var playing = false
    @Published var position: Double = 0
    @Published var seekable = false
    @Published var audio = [Track]()
    @Published var subtitles = [Track]()
    @Published var failure = ""
    @Published var full = false
    private var poll: Task<Void,Never>?
    private var activity: Activity<PlaybackActivity>?
    private var activityTask: Task<Void,Never>?
    private var revision = 0
    private var interruption: NSObjectProtocol?

    init() {
        interruption = NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification,object:nil,queue:.main) { [weak self] note in
            guard let type = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  type == AVAudioSession.InterruptionType.began.rawValue else { return }
            Task { @MainActor in self?.engine.pause() }
        }
    }
    func load(_ url: URL,title: String) {
        stop()
        self.title = title
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback,mode:.moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { failure = "Impossible d’activer l’audio."; return }
        active = true
        UIApplication.shared.isIdleTimerDisabled = true
        engine.media = VLCMedia(url:url)
        engine.play()
        syncActivity()
        poll = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let changed = playing != engine.isPlaying
                playing = engine.isPlaying
                position = Double(max(0,min(1,engine.position)))
                seekable = engine.isSeekable
                audio = Track.read(engine.audioTrackIndexes,engine.audioTrackNames)
                subtitles = Track.read(engine.videoSubTitlesIndexes,engine.videoSubTitlesNames)
                if engine.state == .error { failure = "Le serveur ou le format de ce média empêche sa lecture." }
                if engine.state == .ended || engine.state == .error {
                    UIApplication.shared.isIdleTimerDisabled = false
                }
                if changed { syncActivity() }
                do { try await Task.sleep(for:.milliseconds(500)) } catch { return }
            }
        }
    }
    func suspend() { engine.pause(); playing = false; syncActivity() }
    func toggle() { if engine.isPlaying { engine.pause() } else { engine.play() } }
    func seek(_ value: Double) { if engine.isSeekable { engine.position = Float(value) } }
    func stop() {
        poll?.cancel(); poll = nil
        engine.stop(); engine.media = nil; engine.drawable = nil
        active = false; playing = false; failure = ""; position = 0
        audio = []; subtitles = []; title = ""
        UIApplication.shared.isIdleTimerDisabled = false
        try? AVAudioSession.sharedInstance().setActive(false,options:.notifyOthersOnDeactivation)
        syncActivity()
    }
    private func syncActivity() {
        revision += 1
        let current = revision
        let state = PlaybackActivity.ContentState(title:title,playing:playing)
        let old = activity
        let previous = activityTask
        activityTask = Task {
            await previous?.value
            guard current == revision else { return }
            if !active {
                if let old { await old.end(nil,dismissalPolicy:.immediate) }
                activity = nil
            } else if let activity {
                await activity.update(ActivityContent(state:state,staleDate:Date().addingTimeInterval(120)))
            } else if ActivityAuthorizationInfo().areActivitiesEnabled {
                activity = try? Activity.request(attributes:PlaybackActivity(),content:ActivityContent(state:state,staleDate:Date().addingTimeInterval(120)),pushType:nil)
            }
        }
    }
    func clearStaleActivities() async {
        for old in Activity<PlaybackActivity>.activities { await old.end(nil,dismissalPolicy:.immediate) }
    }
}
struct Track: Identifiable {
    let id: Int32
    let name: String
    static func read(_ ids:[Any],_ names:[Any]) -> [Track] {
        var seen = Set<Int32>()
        return ids.enumerated().compactMap { i,value in
            guard let id = (value as? NSNumber)?.int32Value, seen.insert(id).inserted else { return nil }
            return Track(id:id,name:id == -1 ? "Désactivés" : (names.indices.contains(i) ? names[i] as? String : nil) ?? "Piste \(id)")
        }
    }
}
struct VideoSurface: UIViewRepresentable {
    let playback: Playback
    func makeUIView(context:Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        playback.engine.drawable = view
        return view
    }
    func updateUIView(_ view:UIView,context:Context) {
        if playback.engine.drawable as? UIView !== view { playback.engine.drawable = view }
    }
    static func dismantleUIView(_ view:UIView,coordinator:()) {}
}
