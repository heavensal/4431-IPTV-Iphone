import SwiftUI

enum Theme {
    static let night = Color(red:0.035,green:0.055,blue:0.13)
    static let panel = Color(red:0.085,green:0.105,blue:0.21)
    static let accent = Color(red:0.67,green:0.42,blue:1)
}

@main struct IPTVPhoneApp: App {
    @StateObject private var model = Model()
    var body: some Scene {
        WindowGroup {
            PhoneScreen(model:model,playback:model.playback)
                .preferredColorScheme(.dark).tint(Theme.accent)
                .task {
                    await model.playback.clearStaleActivities()
                    model.restore()
                }
        }
    }
}

struct PhoneScreen: View {
    @ObservedObject var model: Model
    @ObservedObject var playback: Playback
    @Environment(\.scenePhase) private var scenePhase
    @State private var confirmLogout = false
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment:.bottom) {
                Theme.night.ignoresSafeArea()
                NavigationStack {
                    Group {
                        if model.connected { catalogue }
                        else { login }
                    }
                    .background(Theme.night)
                    .navigationTitle(model.connected ? "Explorer" : "4431 IPTV")
                    .toolbar {
                        if model.connected {
                            ToolbarItem(placement:.topBarTrailing) {
                                Button { confirmLogout = true } label: { Image(systemName:"rectangle.portrait.and.arrow.right") }
                                    .accessibilityLabel("Déconnexion et effacement")
                            }
                        }
                    }
                    .safeAreaInset(edge:.bottom) {
                        if playback.active { Color.clear.frame(height:geometry.size.height * 0.32) }
                    }
                }.opacity(playback.full && playback.active ? 0 : 1)
                    .allowsHitTesting(!playback.full || !playback.active)
                if playback.active {
                    PlayerPanel(playback:playback)
                        .frame(width:geometry.size.width,height:playback.full ? geometry.size.height : geometry.size.height * 0.32)
                        .background(.black).clipShape(RoundedRectangle(cornerRadius:playback.full ? 0 : 18))
                }
            }
        }
        .ignoresSafeArea(edges:playback.full && playback.active ? .all : [])
        .onChange(of:model.kind) { _,_ in model.query = ""; model.resetSection() }
        .onChange(of:scenePhase) { _,phase in
            if phase == .background { playback.suspend() }
        }
        .onOpenURL { url in if url.scheme == "iptv4431" && playback.active { playback.full = true } }
        .confirmationDialog("Déconnecter ce compte et effacer ses identifiants ?",isPresented:$confirmLogout) {
            Button("Déconnexion",role:.destructive) { model.logout() }
        }
    }
    private var login: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:20) {
                Image(systemName:"play.tv.fill").font(.system(size:54)).foregroundStyle(Theme.accent)
                Text("Votre cinéma, partout.").font(.largeTitle.bold())
                Text("TV en direct, films et séries dans une seule application.").foregroundStyle(.secondary)
                Picker("Connexion",selection:$model.useProfile) {
                    Text("Compte Xtream").tag(true); Text("URL M3U").tag(false)
                }.pickerStyle(.segmented)
                VStack(spacing:14) {
                    if model.useProfile {
                        TextField("Nom du profil",text:$model.profile.name)
                        TextField("Serveur https://… et port éventuel",text:$model.profile.server).keyboardType(.URL)
                        TextField("Nom d’utilisateur",text:$model.profile.username).textContentType(.username)
                        SecureField("Mot de passe",text:$model.profile.password).textContentType(.password)
                    } else { SecureField("URL get.php complète",text:$model.raw).keyboardType(.URL) }
                }.textInputAutocapitalization(.never).autocorrectionDisabled().textFieldStyle(.roundedBorder)
                if model.loading { ProgressView("Connexion…") }
                else {
                    Button { model.submit() } label: { Label("Se connecter",systemImage:"arrow.right.circle.fill").frame(maxWidth:.infinity) }
                        .buttonStyle(.borderedProminent).controlSize(.large)
                }
                if model.saved || model.loading {
                    Button("Annuler et effacer le compte",role:.destructive) { model.logout() }
                }
                error
            }.padding(24)
        }
    }
    private var catalogue: some View {
        ScrollView {
            LazyVStack(alignment:.leading,spacing:16) {
                Picker("Catalogue",selection:$model.kind) {
                    ForEach(Kind.allCases,id:\.self) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented)
                HStack {
                    TextField("Rechercher dans tout le catalogue",text:$model.query)
                        .submitLabel(.search).onSubmit { search() }
                    Button(action:search) { Image(systemName:"magnifyingglass").frame(width:44,height:44) }
                        .accessibilityLabel("Rechercher")
                }.padding(.horizontal,12).background(Theme.panel,in:RoundedRectangle(cornerRadius:14))
                if !model.heading.isEmpty {
                    series
                } else if model.selected != nil || model.searching {
                    Button { model.query = ""; model.resetSection() } label: { Label("Catégories",systemImage:"chevron.left") }.frame(minHeight:44)
                    Text(model.searching ? "Résultats" : model.selected?.name ?? "").font(.title2.bold())
                }
                error
                if model.browsing { ProgressView("Chargement…").frame(maxWidth:.infinity) }
                else if model.selected == nil && !model.searching && model.useProfile {
                    ForEach(model.groups) { category in
                        Button { model.selected = category; model.browse() } label: {
                            HStack { Image(systemName:"square.grid.2x2"); Text(category.name); Spacer(); Image(systemName:"chevron.right") }
                                .padding(18).background(Theme.panel,in:RoundedRectangle(cornerRadius:16))
                        }.buttonStyle(.plain)
                    }
                    if model.groups.isEmpty { Text("Aucune catégorie disponible.").foregroundStyle(.secondary) }
                } else {
                    LazyVGrid(columns:[GridItem(.adaptive(minimum:145),spacing:14)],spacing:18) {
                        ForEach(model.results) { entry in
                            Button { model.select(entry) } label: {
                                VStack(alignment:.leading,spacing:8) {
                                    Artwork(url:entry.artwork).frame(height:180).clipped().clipShape(RoundedRectangle(cornerRadius:14))
                                    Text(entry.title).font(.subheadline.weight(.semibold)).lineLimit(3)
                                    Text(entry.kind.rawValue).font(.caption).foregroundStyle(.secondary)
                                }.frame(maxWidth:.infinity,alignment:.leading)
                            }.buttonStyle(.plain)
                        }
                    }
                    if model.results.isEmpty { Text("Aucun média trouvé.").foregroundStyle(.secondary) }
                }
            }.padding(18)
        }
    }
    private var series: some View {
        VStack(alignment:.leading,spacing:12) {
            HStack {
                Text(model.heading).font(.title2.bold())
                Spacer()
                Button { model.heading = ""; model.clearEpisodes() } label: { Image(systemName:"xmark.circle.fill").frame(width:44,height:44) }
                    .accessibilityLabel("Fermer les épisodes")
            }
            if model.fetching { ProgressView("Épisodes…") }
            if !model.seasons.isEmpty {
                HStack {
                    Artwork(url:model.children.first?.seasonArt ?? model.seriesCover).frame(width:60,height:70).clipped()
                    Picker("Saison",selection:Binding(get:{model.season},set:{model.changeSeason($0)})) {
                        ForEach(model.seasons,id:\.self) { Text("Saison \($0)").tag($0) }
                    }
                }
                ForEach(model.children) { episode in
                    Button { model.select(episode) } label: {
                        HStack {
                            Artwork(url:episode.artwork ?? model.seriesCover).frame(width:90,height:60).clipped().clipShape(RoundedRectangle(cornerRadius:8))
                            Text(episode.title).lineLimit(3)
                            Spacer(); Image(systemName:"play.circle.fill")
                        }.padding(8).background(Theme.panel,in:RoundedRectangle(cornerRadius:12))
                    }.buttonStyle(.plain)
                }
            }
        }
    }
    @ViewBuilder private var error: some View {
        if !model.error.isEmpty { Text(model.error).font(.callout).foregroundStyle(.red).textSelection(.enabled) }
    }
    private func search() {
        if model.useProfile { model.browse(global:true) } else { model.filter() }
    }
}
struct Artwork: View {
    let url: URL?
    var body: some View {
        AsyncImage(url:url) { image in image.resizable().scaledToFill() } placeholder: {
            ZStack { Theme.panel; Image(systemName:"film").font(.largeTitle).foregroundStyle(Theme.accent.opacity(0.5)) }
        }
    }
}
struct PlayerPanel: View {
    @ObservedObject var playback: Playback
    @State private var visible = true
    @State private var hide: Task<Void,Never>?
    @State private var seeking = false
    @State private var position = 0.0
    @State private var audioPicker = false
    @State private var subtitlePicker = false
    private func interact() {
        visible = true; hide?.cancel()
        hide = Task {
            do { try await Task.sleep(for:.seconds(2)) } catch { return }
            if !seeking && !audioPicker && !subtitlePicker { visible = false }
        }
    }
    var body: some View {
        ZStack {
            VideoSurface(playback:playback)
            Color.clear.contentShape(Rectangle()).onTapGesture { interact() }
            if visible {
                VStack {
                    HStack {
                        Text(playback.title).font(.caption.bold()).lineLimit(1)
                        Spacer()
                        Button { playback.stop() } label: { Image(systemName:"xmark").frame(width:44,height:44) }.accessibilityLabel("Arrêter la lecture")
                    }
                    Spacer()
                    if !playback.failure.isEmpty { Text(playback.failure).font(.caption).foregroundStyle(.red) }
                    HStack(spacing:12) {
                        Button { playback.toggle(); interact() } label: {
                            Image(systemName:playback.playing ? "pause.fill" : "play.fill").frame(width:44,height:44)
                        }.accessibilityLabel(playback.playing ? "Pause" : "Lecture")
                        Button { audioPicker = true; interact() } label: {
                            Image(systemName:"speaker.wave.2").frame(width:44,height:44)
                        }.accessibilityLabel("Langue audio")
                        Button { subtitlePicker = true; interact() } label: {
                            Image(systemName:"captions.bubble").frame(width:44,height:44)
                        }.accessibilityLabel("Sous-titres")
                        Spacer(minLength:0)
                        Button { playback.full.toggle(); interact() } label: {
                            Image(systemName:playback.full ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right").frame(width:44,height:44)
                        }.accessibilityLabel(playback.full ? "Réduire" : "Plein écran")
                    }
                    Slider(value:$position,in:0...1) { editing in
                        seeking = editing
                        if !editing { playback.seek(position) }
                        interact()
                    }.disabled(!playback.seekable)
                }.padding(.horizontal,playback.full ? 60 : 18).padding(.vertical,playback.full ? 48 : 4)
                    .background(LinearGradient(colors:[.black.opacity(0.65),.clear,.black.opacity(0.8)],startPoint:.top,endPoint:.bottom))
            }
        }.foregroundStyle(.white).onAppear { interact() }
            .onChange(of:playback.position) { _,value in if !seeking { position = value } }
            .onChange(of:playback.title) { _,_ in interact() }
            .onDisappear { hide?.cancel() }
            .confirmationDialog("Langue audio",isPresented:$audioPicker) {
                ForEach(playback.audio) { track in
                    Button(track.name) { playback.engine.currentAudioTrackIndex = track.id }
                }
            }
            .confirmationDialog("Sous-titres",isPresented:$subtitlePicker) {
                Button("Désactiver") { playback.engine.currentVideoSubTitleIndex = -1 }
                ForEach(playback.subtitles.filter { $0.id != -1 }) { track in
                    Button(track.name) { playback.engine.currentVideoSubTitleIndex = track.id }
                }
            }
            .onChange(of:audioPicker) { _,_ in interact() }
            .onChange(of:subtitlePicker) { _,_ in interact() }
    }
}
