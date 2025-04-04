//
//  MediaDetailView.swift
//  Iridum
//
//  Created by Francesco on 25/11/24.
//

import AVKit
import SwiftUI
import Kingfisher
import SwiftSoup

struct Episode: Identifiable {
    let id: Int
    let name: String
    let plot: String
    let imageFilename: String
    let number: Int
    let titleId: Int
    
    var playUrl: String {
        return "https://\(AppSettings().baseDomain)/iframe/\(titleId)?episode_id=\(id)"
    }
}

struct MediaView: View {
    let initialTitle: String
    let initialImageUrl: String
    let href: String
    
    @State private var title: String
    @State private var originalTitle: String = ""
    @State private var description: String = ""
    @State private var genres: [String] = []
    @State private var watchUrl: String = ""
    @State private var isLoading: Bool = true
    @State private var runtime: Int = 0
    @State private var seasons: Int = 0
    @State private var releaseDate: String = ""
    @State private var score: String = ""
    @State private var age: String = ""
    @State private var quality: String = ""
    @State private var mainActors: [String] = []
    @State private var directors: [String] = []
    @State private var playUrl: String = ""
    @State private var embedUrl: String = ""
    @State private var playlistUrl: String = ""
    @State private var episodes: [Episode] = []
    @State private var timeObserverToken: Any?
    @State private var player: AVPlayer?
    @State private var isBookmarked: Bool = false
    @State private var selectedSeason: Int = 1
    @State private var showSeasonMenu: Bool = false
    @State private var episodeProgress: [Int: Double] = [:] // [episodeId: progress]
    @State private var overallShowProgress: Double = 0.0
    
    @AppStorage("patchStream") var patchStream = false
    
    @EnvironmentObject private var libraryViewModel: LibraryViewModel
    
    init(title: String, imageUrl: String, href: String) {
        self.initialTitle = title
        self.initialImageUrl = imageUrl
        self.href = href
        self._title = State(initialValue: title)
    }
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading details...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        KFImage(URL(string: initialImageUrl))
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(10)
                            .padding()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(title)
                                .font(.title)
                                .bold()
                                .padding(.horizontal)
                            
                            if !originalTitle.isEmpty && originalTitle != title && UserDefaults.standard.bool(forKey: "showOriginalTitle") {
                                Text(originalTitle)
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                            }
                            
                            HStack(spacing: 16) {
                                if !quality.isEmpty {
                                    Label(quality, systemImage: "film")
                                        .foregroundColor(.secondary)
                                }
                                if runtime > 0 {
                                    Label("\(runtime) min", systemImage: "clock")
                                        .foregroundColor(.secondary)
                                }
                                if !score.isEmpty {
                                    Label("\(score)/10", systemImage: "star.fill")
                                        .foregroundColor(.secondary)
                                }
                                if !age.isEmpty {
                                    Label("\(age)+", systemImage: "person.crop.circle")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            
                            if !genres.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(genres, id: \.self) { genre in
                                            Text(genre)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(Color.accentColor.opacity(0.1))
                                                .cornerRadius(20)
                                                .foregroundColor(.accentColor)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        Button(action: {
                            if !episodes.isEmpty {
                                if let firstEpisodeUrl = getFirstEpisodePlayUrl() {
                                    startMediaUrlChain(url: firstEpisodeUrl)
                                }
                            } else if !playUrl.isEmpty {
                                startMediaUrlChain(url: playUrl)
                            } else if let url = URL(string: watchUrl) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text(!episodes.isEmpty ? "Watch Series" : "Watch Now")
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .disabled(playUrl.isEmpty && watchUrl.isEmpty && episodes.isEmpty)
                        
                        if episodes.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Overall Progress")
                                    .font(.headline)
                                    .padding(.horizontal)
                                ProgressView(value: overallShowProgress)
                                    .padding(.horizontal)
                            }
                        }
                        
                        if !description.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.headline)
                                Text(description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                        
                        if !episodes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                if seasons > 1 {
                                    HStack {
                                        Text("Episodes")
                                            .font(.headline)
                                            .padding(.horizontal)
                                        
                                        Spacer()
                                        
                                        Menu {
                                            ForEach(1...seasons, id: \.self) { season in
                                                Button(action: {
                                                    selectedSeason = season
                                                    fetchMediaDetails()
                                                }) {
                                                    Text("Season \(season)")
                                                }
                                            }
                                        } label: {
                                            Label("Season \(selectedSeason)", systemImage: "chevron.down")
                                                .padding(.horizontal)
                                        }
                                    }
                                } else {
                                    Text("Episodes")
                                        .font(.headline)
                                        .padding(.horizontal)
                                }
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(episodes) { episode in
                                            Button(action: {
                                                startMediaUrlChain(url: episode.playUrl)
                                            }) {
                                                VStack(alignment: .leading, spacing: 8) {
                                                    KFImage(URL(string: "https://cdn.\(AppSettings().baseDomain)/images/\(episode.imageFilename)"))
                                                        .resizable()
                                                        .aspectRatio(16/9, contentMode: .fill)
                                                        .frame(width: 240, height: 135)
                                                        .cornerRadius(8)
                                                    
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text("Episode \(episode.number)")
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                        Text(episode.name)
                                                            .font(.subheadline)
                                                            .foregroundColor(.primary)
                                                        Text(episode.plot)
                                                            .font(.caption2)
                                                            .foregroundColor(.secondary)
                                                            .lineLimit(3)
                                                            .multilineTextAlignment(.leading)
                                                        
                                                        if let progress = episodeProgress[episode.id] {
                                                            ProgressView(value: progress)
                                                                .frame(width: 240)
                                                        }
                                                    }
                                                    .frame(width: 240, alignment: .leading)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        if !mainActors.isEmpty && UserDefaults.standard.bool(forKey: "showCast")  {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Cast")
                                    .font(.headline)
                                Text(mainActors.joined(separator: ", "))
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                        
                        if !directors.isEmpty && UserDefaults.standard.bool(forKey: "showDirector") {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Director")
                                    .font(.headline)
                                Text(directors.joined(separator: ", "))
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarTitle("")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            toggleBookmark()
                        }) {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
        .onAppear {
            fetchMediaDetails()
            checkIfBookmarked()
        }
    }
    
    func checkIfBookmarked() {
        isBookmarked = libraryViewModel.items.contains(where: { $0.href == href })
    }
    
    func fetchMediaDetails() {
        let searchUrl = "\(href)/stagione-\(selectedSeason)"
        
        guard let url = URL(string: searchUrl) else {
            isLoading = false
            return
        }
        
        let task = URLSession.custom.dataTask(with: url) { data, response, error in
            if let error = error {
                Logger.shared.log("Error fetching media details: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            do {
                let document = try SwiftSoup.parse(html)
                
                if let appDiv = try document.getElementById("app") {
                    let dataPage = try appDiv.attr("data-page")
                    if let jsonData = dataPage.data(using: .utf8) {
                        if let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                           let props = json["props"] as? [String: Any],
                           let titleData = props["title"] as? [String: Any] {
                            DispatchQueue.main.async {
                                self.title = titleData["name"] as? String ?? ""
                                self.originalTitle = titleData["original_name"] as? String ?? ""
                                self.description = titleData["plot"] as? String ?? ""
                                self.runtime = titleData["runtime"] as? Int ?? 0
                                self.releaseDate = titleData["release_date"] as? String ?? ""
                                self.score = titleData["score"] as? String ?? ""
                                self.quality = titleData["quality"] as? String ?? ""
                                self.seasons = titleData["seasons_count"] as? Int ?? 0
                                
                                if let genresData = titleData["genres"] as? [[String: Any]] {
                                    self.genres = genresData.compactMap { $0["name"] as? String }
                                }
                                
                                if let actorsData = titleData["main_actors"] as? [[String: Any]] {
                                    self.mainActors = actorsData.compactMap { $0["name"] as? String }
                                }
                                
                                if let directorsData = titleData["main_directors"] as? [[String: Any]] {
                                    self.directors = directorsData.compactMap { $0["name"] as? String }
                                }
                                
                                if let ageValue = titleData["age"] as? Int {
                                    self.age = "\(ageValue)"
                                } else if let ageString = titleData["age"] as? String {
                                    self.age = ageString
                                } else {
                                    self.age = ""
                                }
                                
                                if let id = titleData["id"] as? Int {
                                    self.playUrl = "https://\(AppSettings().baseDomain)/iframe/\(id)"
                                }
                                
                                self.isLoading = false
                                if let episodesData = props["loadedSeason"] as? [String: Any],
                                   let episodesList = episodesData["episodes"] as? [[String: Any]],
                                   let titleId = episodesData["title_id"] as? Int {
                                    self.episodes = episodesList.compactMap { episodeData in
                                        guard let id = episodeData["id"] as? Int,
                                              let name = episodeData["name"] as? String,
                                              let plot = episodeData["plot"] as? String,
                                              let number = episodeData["number"] as? Int,
                                              let images = episodeData["images"] as? [[String: Any]],
                                              let firstImage = images.first,
                                              let filename = firstImage["filename"] as? String else {
                                                  return nil
                                              }
                                        
                                        return Episode(id: id, name: name, plot: plot, imageFilename: filename, number: number, titleId: titleId)
                                    }
                                }
                            }
                        }
                    }
                }
                
            } catch {
                Logger.shared.log("Error parsing media details: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
        
        task.resume()
    }
    
    func toggleBookmark() {
        if isBookmarked {
            libraryViewModel.removeItem(withHref: href)
            isBookmarked = false
        } else {
            let newBookmark = LibraryItem(
                title: title,
                imageUrl: initialImageUrl,
                href: href,
                isFavorite: false,
                isFinished: false
            )
            libraryViewModel.addItem(newBookmark)
            isBookmarked = true
        }
    }
    
    func startMediaUrlChain(url: String) {
        guard let url = URL(string: url) else {
            Logger.shared.log("Invalid play URL")
            return
        }
        
        URLSession.custom.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                Logger.shared.log("Error fetching play URL: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let html = String(data: data, encoding: .utf8) {
                do {
                    let document = try SwiftSoup.parse(html)
                    if let newEmbedUrl = try document.select("iframe").first()?.attr("src") {
                        fetchPlaylistUrl(from: newEmbedUrl, fullUrl: url.absoluteString)
                    }
                } catch {
                    Logger.shared.log("Error parsing play URL HTML: \(error)")
                }
            }
        }.resume()
    }
    
    func getFirstEpisodePlayUrl() -> String? {
        return episodes.first?.playUrl
    }
    
    func fetchPlaylistUrl(from embedUrl: String, fullUrl: String) {
        guard let url = URL(string: embedUrl) else {
            return
        }
        
        URLSession.custom.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                Logger.shared.log("Error fetching embed URL: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let html = String(data: data, encoding: .utf8) {
                if html.contains("window.masterPlaylist") {
                    do {
                        let urlPattern = #"url:\s*'([^']+)'"#
                        guard let urlRegex = try? NSRegularExpression(pattern: urlPattern),
                              let urlMatch = urlRegex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
                              let urlRange = Range(urlMatch.range(at: 1), in: html) else {
                                  Logger.shared.log("Failed to extract URL")
                                  return
                              }
                        let baseUrl = String(html[urlRange])
                        
                        let tokenPattern = #"'token':\s*'([^']+)'"#
                        guard let tokenRegex = try? NSRegularExpression(pattern: tokenPattern),
                              let tokenMatch = tokenRegex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
                              let tokenRange = Range(tokenMatch.range(at: 1), in: html) else {
                                  Logger.shared.log("Failed to extract token")
                                  return
                              }
                        let token = String(html[tokenRange])
                        
                        let expiresPattern = #"'expires':\s*'([^']+)'"#
                        guard let expiresRegex = try? NSRegularExpression(pattern: expiresPattern),
                              let expiresMatch = expiresRegex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
                              let expiresRange = Range(expiresMatch.range(at: 1), in: html) else {
                                  Logger.shared.log("Failed to extract expires")
                                  return
                              }
                        let expires = String(html[expiresRange])
                        
                        let finalUrl: String
                        if baseUrl.hasSuffix("?b=1") {
                            finalUrl = "\(baseUrl)&token=\(token)&expires=\(expires)\(patchStream ? "&h=1" : "")"
                        } else {
                            finalUrl = "\(baseUrl)?token=\(token)&expires=\(expires)\(patchStream ? "&h=1" : "")"
                        }
                        
                        DispatchQueue.main.async {
                            self.playlistUrl = finalUrl
                            Logger.shared.log("Final playlist URL: \(finalUrl)")
                            
                            if let url = URL(string: finalUrl) {
                                let headers = [
                                    "Referer": embedUrl,
                                    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:135.0) Gecko/20100101 Firefox/135.0"
                                ]
                                let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
                                
                                let playerItem = AVPlayerItem(asset: asset)
                                
                                let newPlayer = AVPlayer(playerItem: playerItem)
                                self.player = newPlayer
                                let playerViewController = NormalPlayer()
                                playerViewController.player = newPlayer
                                
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let rootVC = windowScene.windows.first?.rootViewController {
                                    rootVC.present(playerViewController, animated: true) {
                                        let lastPlayedTime = UserDefaults.standard.double(forKey: "lastPlayedTime_\(fullUrl)")
                                        if lastPlayedTime > 0 {
                                            let seekTime = CMTime(seconds: lastPlayedTime, preferredTimescale: 1)
                                            newPlayer.seek(to: seekTime) { _ in
                                                newPlayer.play()
                                            }
                                        } else {
                                            newPlayer.play()
                                        }
                                        self.addPeriodicTimeObserver(fullURL: fullUrl)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Logger.shared.log("No window.masterPlaylist found in the HTML")
                }
            }
        }.resume()
    }
    
    func addPeriodicTimeObserver(fullURL: String) {
        guard let player = self.player else { return }
        
        let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            guard let currentItem = player.currentItem,
                  currentItem.duration.seconds.isFinite else {
                      return
                  }
            
            let currentTime = time.seconds
            let duration = currentItem.duration.seconds
            
            UserDefaults.standard.set(currentTime, forKey: "lastPlayedTime_\(fullURL)")
            UserDefaults.standard.set(duration, forKey: "totalTime_\(fullURL)")
            
            if let episode = episodes.first(where: { fullURL.contains("\($0.id)") }) {
                let progress = currentTime / duration
                episodeProgress[episode.id] = progress
                
                let totalProgress = episodeProgress.values.reduce(0, +)
                overallShowProgress = totalProgress / Double(episodes.count)
            }
        }
    }
}
