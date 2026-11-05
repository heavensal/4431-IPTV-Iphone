import SwiftUI
import UIKit
import Security

enum Vault {
    static let key: [String:Any] = [kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:"local.heavensal.4431iphone",kSecAttrAccount as String:"playlist"]
    static func read() throws -> String? {
        var q = key; q[kSecReturnData as String] = true
        var result: CFTypeRef?
        let status = SecItemCopyMatching(q as CFDictionary,&result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let d = result as? Data else { throw Failure.secrets }
        return String(data:d,encoding:.utf8)
    }
    static func save(_ s: String) throws {
        let data = Data(s.utf8)
        var q = key; q[kSecValueData as String] = data; q[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let status = SecItemAdd(q as CFDictionary,nil)
        if status == errSecDuplicateItem {
            guard SecItemUpdate(key as CFDictionary,[kSecValueData as String:data] as CFDictionary) == errSecSuccess else { throw Failure.secrets }
        } else if status != errSecSuccess { throw Failure.secrets }
    }
    static func clear() throws {
        let status = SecItemDelete(key as CFDictionary)
        guard [errSecSuccess,errSecItemNotFound].contains(status) else { throw Failure.secrets }
    }
}
@MainActor final class Model: ObservableObject {
    let playback = Playback()
    @Published var profile = Profile()
    @Published var useProfile = true
    @Published var raw = ""
    @Published var error = ""
    @Published var loading = false
    @Published var connected = false
    @Published var saved = false
    @Published var kind = Kind.tv
    @Published var query = ""
    @Published var results = [Entry]()
    @Published var children = [Entry]()
    private var seasonRows = [Int:[Entry]]()
    @Published var seasons = [Int]()
    @Published var season = 0
    @Published var embeddedURL: URL?
    func changeSeason(_ value: Int) { season = value; children = seasonRows[value] ?? [] }
    func clearEpisodes() { seasonRows = [:]; seasons = []; children = [] }
    @Published var seriesCover: URL?
    @Published var heading = ""
    @Published var media = ""
    @Published var fetching = false
    @Published var groups = [Category]()
    @Published var selected: Category?
    @Published var browsing = false
    @Published var searching = false
    private var liveExt = "m3u8"
    private var provider: Provider?, index = [(Entry,String)]()
    private var session: Task<Void,Never>?, search: Task<Void,Never>?, detail: Task<Void,Never>?
    func restore() {
        do { if let s = try Vault.read() { saved = true; if let stored = try? JSONDecoder().decode(Profile.self,from:Data(s.utf8)) { profile = stored; useProfile = true; submit() } else { useProfile = false; raw = s; submit() } } }
        catch { self.error = error.localizedDescription }
    }
    func submit() {
        let p: Provider, s: String
        do {
            if useProfile { p = try profile.provider(); s = String(decoding:try JSONEncoder().encode(profile),as:UTF8.self) }
            else { p = try Provider(raw); s = raw }
        } catch { self.error = connectionMessage(error); return }
        session?.cancel(); error = ""
        let apiMode = useProfile
        loading = true
        session = Task {
            do {
                var items = [Entry]()
                if apiMode { liveExt = try await authenticate(p) }
                else { items = try await playlist(p); if let extra = try? await shows(p) { items += extra } }
                try Task.checkCancellation()
                guard apiMode || !items.isEmpty else { throw Failure.empty }
                let snapshot = items
                let indexed = await Task.detached { snapshot.map { ($0,$0.needle) } }.value
                try Task.checkCancellation()
                try Vault.save(s); profile.password = ""; raw = ""; saved = true; provider = p; index = indexed; connected = true; filter()
            } catch { if !Task.isCancelled { self.error = connectionMessage(error) } }
            if !Task.isCancelled { loading = false }
        }
    }
    func filter() {
        search?.cancel()
        guard connected else { return }
        if useProfile { browse(); return }
        let all = index, k = kind, term = query.trimmingCharacters(in:.whitespaces).folding(options:[.caseInsensitive,.diacriticInsensitive],locale:.current)
        search = Task {
            let worker = Task.detached {
                all.filter { item, name in term.isEmpty ? item.kind == k : name.contains(term) }.map { $0.0 }
            }
            let found = await worker.value
            guard !Task.isCancelled else { return }
            results = found
        }
    }

    func browse(global: Bool = false) {
        search?.cancel()
        guard let p = provider else { return }
        let k = kind, group = selected, ext = liveExt
        let term = query.trimmingCharacters(in:.whitespacesAndNewlines)
        searching = global && !term.isEmpty
        let runSearch = searching
        results = []; browsing = true; error = ""
        search = Task {
            defer { if !Task.isCancelled { browsing = false } }
            do {
                if runSearch {
                    var hits = [Entry]()
                    var failures = [String]()
                    for section in Kind.allCases {
                        try Task.checkCancellation()
                        do { hits += try await mediaRows(p,kind:section,category:nil,liveExt:ext,matching:term,offset:hits.count) }
                        catch { failures.append(section.rawValue + " · " + connectionMessage(error)) }
                    }
                    try Task.checkCancellation(); results = hits; error = failures.joined(separator:" · ")
                } else if let group {
                    let rows = try await mediaRows(p,kind:k,category:group,liveExt:ext)
                    try Task.checkCancellation(); results = rows
                } else {
                    groups = []
                    let rows = try await categories(p,kind:k)
                    try Task.checkCancellation(); groups = rows
                }
            } catch { if !Task.isCancelled { self.error = connectionMessage(error) } }
        }
    }
    func resetSection() {
        selected = nil; groups = []; detail?.cancel(); fetching = false; heading = ""; clearEpisodes()
        filter()
    }
    func stop() { playback.stop(); embeddedURL = nil; media = "" }
    func select(_ item: Entry) {
        detail?.cancel(); fetching = false; error = ""
        if let id = item.remote, let provider {
            heading = item.title; seriesCover = item.artwork; clearEpisodes(); fetching = true
            detail = Task {
                do { let rows = try await episodes(provider,id); try Task.checkCancellation(); seasonRows = Dictionary(grouping:rows) { $0.season ?? 0 }; seasons = seasonRows.keys.sorted(); changeSeason(seasons.first ?? 0) }
                catch { if !Task.isCancelled { self.error = Failure.episodes.localizedDescription } }
                if !Task.isCancelled { fetching = false }
            }
        } else if let url = item.url {
            if !children.contains(where: { $0.url == url }) { clearEpisodes(); heading = "" }
            media = item.title; embeddedURL = url; playback.load(url,title:item.title)
        }
    }
    func logout() {
        session?.cancel(); detail?.cancel(); search?.cancel(); stop()
        groups = []; selected = nil; searching = false; browsing = false; profile = Profile(); index = []; provider = nil; results = []; clearEpisodes(); heading = ""; raw = ""; query = ""; connected = false; loading = false; fetching = false; error = ""
        do { try Vault.clear(); saved = false } catch { saved = true; self.error = error.localizedDescription }
    }
}
