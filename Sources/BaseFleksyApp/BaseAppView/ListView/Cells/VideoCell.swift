//  VideoCell.swift
//  FleksyApps
//
//  Copyright © 2023 Thingthing. All rights reserved.
//


import UIKit
import FleksyAppsCore

class VideoCell: BaseAppCell<VideoPlayerView> {
    
    private var videoView: VideoPlayerView { viewContent }
        
    override func prepareForReuse() {
        super.prepareForReuse()
        videoView.resetVideoPlayer()
    }
    
    // MARK: - Interface methods
    
    /// It could happen that there's no file at `localURL` yet. In that case, calling this method shows the loader in the cell.
    /// - Parameter localURL: The url to the local video.
    /// - Returns: Whether or not the video in the given url was loaded.
    @MainActor
    func loadMedia(localURL: URL, autoplay: Bool) -> Bool {
        showLoader()
        fileURL = localURL
        return loadVideoURL(localURL, autoplay: autoplay)
    }
    
    
    /// Calling this method makes the cell play the video from the passed url only if it matches the url passed in the `loadMedia(localURL:)` method. Otherwise, this call is ignored (since it corresponds to a previous url before the cell has been reused)
    /// If the urls match but there's no file in the url, then it's treated as an error and an error image is shown
    @MainActor
    func forceLoadMedia(localURL: URL, autoplay: Bool) {
        guard localURL == self.fileURL else {
            return
        }
        let videoLoaded = loadVideoURL(localURL, autoplay: autoplay)
        if videoLoaded {
            hideContentError()
        } else {
            hideLoader()
            showContentError()
        }
    }
    
    /// Stops playback and resets the video player.
    @MainActor
    func stopPlayback() {
        videoView.resetVideoPlayer()
    }
    
    @MainActor
    private func loadVideoURL(_ url: URL, autoplay: Bool) -> Bool {
        if FileManager.default.fileExists(atPath: url.path) {
            showLoader()
            videoView.setVideoWithUrl(url, startPlayback: autoplay) { [weak self] in
                self?.hideLoader()
            }
            return true
        } else {
            return false
        }
    }
}
