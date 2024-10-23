//  VideoCell.swift
//  FleksyApps
//
//  Copyright © 2023 Thingthing. All rights reserved.
//


import UIKit
import FleksyAppsCore

protocol VideoCellDelegate: AnyObject {
    
    /// Executed on the delegate when a muted video playback is going to start, either muted or unmuted.
    func videoCellWillStartPlayingVideo(_ videoCell: VideoCell)
    
    /// Executed on the delegate when the user toggles ON the audio playback button.
    func videoCellWillUnmuteAudio(_ videoCell: VideoCell)
}

class VideoCell: BaseAppCell<VideoPlayerView> {
    
    private var videoView: VideoPlayerView { viewContent }
    private var audioToggle: Bool = false
    private weak var delegate: VideoCellDelegate?
    
    override var appTheme: AppTheme? {
        didSet {
            updateForTheme()
        }
    }
    
    private lazy var audioToggleButton: UIButton = {
        let audioOnIcon = UIImage(systemName: "speaker.wave.2") ?? UIImage(systemName: "speaker")
        let audioOffIcon = UIImage(systemName: "speaker.slash")
        
        let audioToggleButton = UIButton(type: .custom)
        audioToggleButton.setTitle(nil, for: .normal)
        audioToggleButton.setImage(audioOnIcon, for: .selected)
        audioToggleButton.setImage(audioOffIcon, for: .normal)
        audioToggleButton.addTarget(self, action: #selector(toggleAudio(sender:)), for: .touchUpInside)
        audioToggleButton.contentMode = .center
        return audioToggleButton
    }()
    
    private lazy var viewContainerLabel = GradientView()
    
    private lazy var titleLabel: UILabel = {
        let lb = UILabel()
        lb.textAlignment = .natural
        lb.numberOfLines = 2
        lb.adjustsFontSizeToFitWidth = true
        lb.minimumScaleFactor = 0.8
        lb.baselineAdjustment = .alignBaselines
        return lb
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        stopPlayback()
    }
    
    override func layoutSubviews() {
        updateTitleFont()
        super.layoutSubviews()
    }
    
    // MARK: - Interface methods
    
    /// It could happen that there's no file at `localURL` yet. In that case, calling this method shows the loader in the cell.
    /// - Parameters:
    ///   - localURL: The url to the local video.
    ///   - title: An optional title to show on the video.
    ///   - autoplay: Whether or not the video should autoplay.
    ///   - audioToggle: Whether or not the video cell should show a button to play the video with sound.
    ///   - delegate: The object to which to send video playback events callbacks.
    /// - Returns: Whether or not the video in the given url was loaded.
    @MainActor
    func loadMedia(localURL: URL, title: String?, autoplay: Bool, audioToggle: Bool, delegate: VideoCellDelegate) -> Bool {
        showLoader()
        self.delegate = delegate
        
        titleLabel.text = title
        let hideLabelContainer = title?.isEmpty ?? true
        viewContainerLabel.isHidden = hideLabelContainer
        
        audioToggleButton.isHidden = !audioToggle
        
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
        audioToggleButton.isSelected = false
        videoView.resetVideoPlayer()
    }
    
    /// Mutes the audio of the video, but keeps the video playback (if on).
    @MainActor
    func muteAudio() {
        setAudio(muted: true)
        audioToggleButton.isSelected = false
    }
    
    // MARK: - Actions
    
    @MainActor
    @objc func toggleAudio(sender: UIButton) {
        sender.isSelected.toggle()
        let audioOn = sender.isSelected
        if audioOn {
            delegate?.videoCellWillUnmuteAudio(self)
        }
        setAudio(muted: !audioOn)
    }
    
    // MARK: - Private methods
    
    @MainActor
    private func setAudio(muted: Bool) {
        videoView.setAudio(muted: muted)
    }
    
    @MainActor
    private func loadVideoURL(_ url: URL, autoplay: Bool) -> Bool {
        if FileManager.default.fileExists(atPath: url.path) {
            delegate?.videoCellWillStartPlayingVideo(self)
            showLoader()
            videoView.setVideoWithUrl(url, startPlayback: autoplay) { [weak self] in
                self?.hideLoader()
            }
            return true
        } else {
            return false
        }
    }
    
    @MainActor
    private func setup() {
        audioToggleButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(audioToggleButton)
        
        viewContainerLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(viewContainerLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        viewContainerLabel.addSubview(titleLabel)
        
        let btnWidth: CGFloat = 34
        
        let widthConstraint = audioToggleButton.widthAnchor.constraint(equalToConstant: btnWidth)
        widthConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            audioToggleButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            audioToggleButton.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -4),
            audioToggleButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            audioToggleButton.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 4),
            audioToggleButton.widthAnchor.constraint(equalTo: audioToggleButton.heightAnchor),
            widthConstraint,
            
            viewContainerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            viewContainerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            viewContainerLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            viewContainerLabel.heightAnchor.constraint(lessThanOrEqualTo: contentView.heightAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: viewContainerLabel.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: viewContainerLabel.trailingAnchor, constant: -10),
            titleLabel.topAnchor.constraint(equalTo: viewContainerLabel.topAnchor, constant: 10),
            titleLabel.lastBaselineAnchor.constraint(equalTo: viewContainerLabel.bottomAnchor, constant: -10),
        ])
        
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        
        audioToggleButton.layer.cornerRadius = btnWidth / 2
        audioToggleButton.layer.masksToBounds = true
        
        // Fixed colors for the overlays on the video cell
        audioToggleButton.backgroundColor = .black.withAlphaComponent(0.5)
        audioToggleButton.tintColor = .white
        viewContainerLabel.colors = [.black.withAlphaComponent(0),
                                     .black.withAlphaComponent(0.7)]
        
        titleLabel.textColor = .white
    }
    
    private func updateForTheme() {
        guard let appTheme else {
            return
        }
        updateTitleFont()
    }
    
    private func updateTitleFont() {
        guard let appTheme else {
            return
        }
        var font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: appTheme.font.withSize(UIFont.labelFontSize))
        let maxFontSize = bounds.height / 6 // So that 2 lines don't ever take up more than 1/3 of the height
        if font.pointSize > maxFontSize {
            font = font.withSize(maxFontSize)
        }
        titleLabel.font = font
    }
}

fileprivate class GradientView: UIView {
    override open class var layerClass: AnyClass {
       return CAGradientLayer.classForCoder()
    }
    
    private var gradientLayer: CAGradientLayer {
        layer as! CAGradientLayer
    }
    
    var colors: [UIColor] {
        get {
            let colors: [CGColor] = gradientLayer.colors as? [CGColor] ?? []
            return colors.map {
                UIColor(cgColor: $0 as CGColor)
            }
        }
        set {
            gradientLayer.colors = newValue.map { $0.cgColor }
        }
    }
}
