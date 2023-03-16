//  VideoPlayerView.swift
//  FleksyApps
//
//  Copyright © 2023 Thingthing. All rights reserved.
//

import UIKit
import AVKit
import FleksyAppsCore

class VideoPlayerView: UIView {
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    
    @MainActor
    private var shouldBePlaying: Bool = false
    var isPlaying: Bool {
        return (playerLayer.player?.rate ?? 0) > 0
    }
    
    var isReadyToPlay: Bool {
        if let item = player?.currentItem, item.status == .readyToPlay {
            return true
        } else {
            return false
        }
    }
    
    private var currentPlayerLooper: AVPlayerLooper?
    
    private var player: AVPlayer? {
        get {
            playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
      
    private var videoLoadTask: Task<Void, Never>?
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.videoGravity = .resizeAspectFill
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Inteface
    
    /// Loads the video from the passed local `url`.
    /// - Parameters:
    ///   - url: The local URL where the video is stored.
    ///   - startPlayback: Whether playback should start automatically upon loading the video from the url.
    ///   - onVideoLoaded: Only gets executed when the video loads successfully. If the task is cancelled, it is not executed.
    @MainActor
    func setVideoWithUrl(_ url: URL, startPlayback: Bool = true, onVideoLoaded: @escaping @MainActor () -> Void ) {
        resetVideoPlayer()
        videoLoadTask = Task.detached(priority: .background) {
            let item = AVPlayerItem(url: url)
            let player = AVPlayer(playerItem: item)
            player.isMuted = true
            await MainActor.run {
                self.addNotificationsObserver(to: item)
                self.playerLayer.player = player
            }
            
            let shouldBePlaying = await self.shouldBePlaying
            
            if Task.isCancelled { return }
            if (startPlayback || shouldBePlaying) {
                await self.play()
            }
            
            if Task.isCancelled { return }
            await onVideoLoaded()
        }
    }
    
    @MainActor
    func play() {
        shouldBePlaying = true
        player?.play()
    }
    
    @MainActor
    func pause() {
        shouldBePlaying = false
        player?.pause()
    }
     
    @MainActor
    func resetVideoPlayer() {
        videoLoadTask?.cancel()
        videoLoadTask = nil
        removeNotificationsObserver()
        playerLayer.player = nil
        shouldBePlaying = false
    }
    
    @objc func playerItemDidPlayToEndTime(_ notification: Notification) {
        Task(priority: .userInitiated) {
            await MainActor.run {
                if self.shouldBePlaying {
                    self.player?.seek(to: .zero)
                    self.play()
                }
            }
        }
    }
    
    // MARK: - Private methods
    
    private func removeNotificationsObserver() {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    private func addNotificationsObserver(to item: AVPlayerItem) {
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEndTime), name: .AVPlayerItemDidPlayToEndTime, object: item)
    }
}
