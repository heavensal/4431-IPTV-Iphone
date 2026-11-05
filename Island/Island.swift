import ActivityKit
import WidgetKit
import SwiftUI

@main struct IPTVIsland: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for:PlaybackActivity.self) { context in
            HStack {
                Image(systemName:context.state.playing ? "play.tv.fill" : "pause.circle.fill").foregroundStyle(.purple)
                VStack(alignment:.leading) {
                    Text("4431 IPTV").font(.caption)
                    Text(context.state.title).lineLimit(2).font(.headline)
                }
                Spacer()
                Link(destination:URL(string:"iptv4431://player")!) { Image(systemName:"arrow.up.right.square") }
            }.padding().activityBackgroundTint(Color(red:0.04,green:0.06,blue:0.14)).activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { Image(systemName:"play.tv.fill").foregroundStyle(.purple) }
                DynamicIslandExpandedRegion(.trailing) { Text(context.state.playing ? "Lecture" : "Pause").font(.caption) }
                DynamicIslandExpandedRegion(.bottom) {
                    Link(destination:URL(string:"iptv4431://player")!) {
                        Label(context.state.title,systemImage:"arrow.up.right.square").lineLimit(2)
                    }
                }
            } compactLeading: { Image(systemName:"play.tv.fill").foregroundStyle(.purple) }
              compactTrailing: { Image(systemName:context.state.playing ? "waveform" : "pause.fill") }
              minimal: { Image(systemName:"play.tv.fill").foregroundStyle(.purple) }
            .widgetURL(URL(string:"iptv4431://player"))
            .keylineTint(.purple)
        }
    }
}
