import XCTest
import UIKit
@testable import IPTVPhone

final class PlaybackTests: XCTestCase {
    @MainActor func testLocalVideoDecodesAndStops() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".y4m")
        defer { try? FileManager.default.removeItem(at:url) }
        var data = Data("YUV4MPEG2 W64 H64 F25:1 Ip A1:1 C420jpeg\n".utf8)
        let frame = Data("FRAME\n".utf8) + Data(repeating:90,count:4096) + Data(repeating:128,count:2048)
        for _ in 0..<150 { data.append(frame) }
        try data.write(to:url)
        let playback = Playback()
        let surface = UIView(frame:CGRect(x:0,y:0,width:64,height:64))
        playback.load(url,title:"Vidéo de test")
        playback.engine.drawable = surface
        defer { playback.stop() }
        for _ in 0..<50 {
            if (playback.engine.media?.numberOfDecodedVideoBlocks ?? 0) > 0 { break }
            try await Task.sleep(for:.milliseconds(100))
        }
        XCTAssertGreaterThan(playback.engine.media?.numberOfDecodedVideoBlocks ?? 0,0)
        playback.stop()
        XCTAssertFalse(playback.active)
        XCTAssertNil(playback.engine.media)
    }
}
