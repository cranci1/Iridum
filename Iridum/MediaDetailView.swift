//
//  MediaDetailView.swift
//  Iridum
//
//  Created by Francesco on 25/11/24.
//

import SwiftUI
import Kingfisher
import SwiftSoup
import AVKit

struct MediaDetailView: View {
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
    @State private var releaseDate: String = ""
    @State private var score: String = ""
    @State private var age: String = ""
    @State private var quality: String = ""
    @State private var mainActors: [String] = []
    @State private var directors: [String] = []
    @State private var playUrl: String = ""
    @State private var embedUrl: String = ""
    @State private var playlistUrl: String = ""
    
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
                                .font(.largeTitle)
                            if !originalTitle.isEmpty && originalTitle != title {
                                Text(originalTitle)
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                            
                            HStack(spacing: 16) {
                                HStack(spacing: 8) {
                                    if !quality.isEmpty {
                                        HStack(spacing: 2) {
                                            Image(systemName: "film")
                                                .foregroundColor(.secondary)
                                            Text(quality)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    if runtime > 0 {
                                        HStack(spacing: 2) {
                                            Image(systemName: "clock")
                                                .foregroundColor(.secondary)
                                            Text("\(runtime)min")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                Spacer()
                                HStack(spacing: 8) {
                                    if !score.isEmpty {
                                        HStack(spacing: 2) {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.secondary)
                                            Text("\(score)/10")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    if !age.isEmpty {
                                        HStack(spacing: 2) {
                                            Image(systemName: "person.2.fill")
                                                .foregroundColor(.secondary)
                                            Text(age + "+")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                            
                            if !genres.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(genres, id: \.self) { genre in
                                            Text(genre)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.gray.opacity(0.2))
                                                .cornerRadius(15)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        
                        if !releaseDate.isEmpty {
                            Text("Released: \(releaseDate)")
                                .font(.subheadline)
                                .padding(.horizontal)
                        }
                        
                        if !description.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Description")
                                    .font(.headline)
                                Text(description)
                            }
                            .padding(.horizontal)
                        }
                        
                        if !mainActors.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Cast")
                                    .font(.headline)
                                Text(mainActors.joined(separator: ", "))
                            }
                            .padding(.horizontal)
                        }
                        
                        if !directors.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Director")
                                    .font(.headline)
                                Text(directors.joined(separator: ", "))
                            }
                            .padding(.horizontal)
                        }
                        
                        Button(action: {
                            if !playUrl.isEmpty {
                                startMediaUrlChain()
                            } else if let url = URL(string: watchUrl) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text("Watch Now")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .cornerRadius(10)
                        }
                        .padding()
                        .disabled(watchUrl.isEmpty && playUrl.isEmpty)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onAppear {
            fetchMediaDetails()
        }
    }
    
    func fetchMediaDetails() {
        let searchUrl = href
        
        guard let url = URL(string: searchUrl) else {
            isLoading = false
            return
        }
        
        DispatchQueue.global().async {
            do {
                let html = try String(contentsOf: url)
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
                                self.isLoading = false
                            }
                        }
                    }
                }
                
                if let playButton = try document.select("a.play").first() {
                    let playUrl = try playButton.attr("href").replacingOccurrences(of: "watch", with: "iframe")
                    DispatchQueue.main.async {
                        self.playUrl = playUrl
                    }
                }
                
            } catch {
                print("Error fetching media details: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    func startMediaUrlChain() {
        guard let url = URL(string: playUrl) else {
            print("Invalid play URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching play URL: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let html = String(data: data, encoding: .utf8) {
                do {
                    let document = try SwiftSoup.parse(html)
                    if let newEmbedUrl = try document.select("iframe").first()?.attr("src") {
                        fetchPlaylistUrl(from: newEmbedUrl)
                        print("Embed URL: \(newEmbedUrl)")
                    }
                } catch {
                    print("Error parsing play URL HTML: \(error)")
                }
            }
        }.resume()
    }
    
    func fetchPlaylistUrl(from embedUrl: String) {
        guard let url = URL(string: embedUrl) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching embed URL: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let html = String(data: data, encoding: .utf8) {
                let pattern = #"https:\/\/vixcloud\.co\/playlist\/\d+"#
                if let regex = try? NSRegularExpression(pattern: pattern, options: []),
                   let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: html.utf16.count)) {
                    
                    let start = html.index(html.startIndex, offsetBy: match.range.location)
                    let end = html.index(start, offsetBy: match.range.length)
                    var extractedUrl = String(html[start..<end])
                    
                    if extractedUrl.hasSuffix("'") {
                        extractedUrl.removeLast()
                    }
                    
                    DispatchQueue.main.async {
                        self.playlistUrl = extractedUrl
                        print("Found Playlist URL: \(extractedUrl)")
                        
                        if let url = URL(string: extractedUrl) {
                            setupAudioSession()
                            let player = AVPlayer(url: url)
                            let playerViewController = NormalPlayer()
                            playerViewController.player = player
                            
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let rootVC = windowScene.windows.first?.rootViewController {
                                rootVC.present(playerViewController, animated: true) {
                                    player.play()
                                }
                            }
                        }
                    }
                } else {
                    print("No matching URL found in the HTML")
                }
            }
        }.resume()
    }
    
    func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .moviePlayback, options: .mixWithOthers)
            try audioSession.setActive(true)
            
            try audioSession.overrideOutputAudioPort(.speaker)
        } catch {
            print("Failed to set up AVAudioSession: \(error)")
        }
    }
}

class NormalPlayer: AVPlayerViewController {
    private var originalRate: Float = 1.0
    private var holdGesture: UILongPressGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupHoldGesture()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UserDefaults.standard.bool(forKey: "AlwaysLandscape") {
            return .landscape
        } else {
            return .all
        }
    }
    
    private func setupHoldGesture() {
        holdGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleHoldGesture(_:)))
        holdGesture?.minimumPressDuration = 0.5
        if let holdGesture = holdGesture {
            view.addGestureRecognizer(holdGesture)
        }
    }
    
    @objc private func handleHoldGesture(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            beginHoldSpeed()
        case .ended, .cancelled:
            endHoldSpeed()
        default:
            break
        }
    }
    
    private func beginHoldSpeed() {
        guard let player = player else { return }
        originalRate = player.rate
        let holdSpeed = UserDefaults.standard.float(forKey: "holdSpeedPlayer")
        player.rate = holdSpeed
    }
    
    private func endHoldSpeed() {
        player?.rate = originalRate
    }
}
