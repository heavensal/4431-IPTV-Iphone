import ActivityKit

struct PlaybackActivity: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var title: String
        var playing: Bool
    }
    var appName: String = "4431 IPTV"
}
