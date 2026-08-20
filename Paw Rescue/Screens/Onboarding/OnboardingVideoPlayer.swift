import SwiftUI
import AVKit

/// The looping video player for the onboarding screen.
/// Loads video asynchronously to avoid blocking the main thread.
struct OnboardingVideoPlayer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> VideoPlayerUIView {
        let view = VideoPlayerUIView()
        view.isUserInteractionEnabled = false
        return view
    }
    
    func updateUIView(_ uiView: VideoPlayerUIView, context: Context) {}
}

final class VideoPlayerUIView: UIView {
    private var playerLayer = AVPlayerLayer()
    private var player: AVPlayer?
    private var loopObserver: Any?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(AppColors.secondaryCream)
        clipsToBounds = true
        isUserInteractionEnabled = false
        setupPlayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPlayer()
    }
    
    private func setupPlayer() {
        guard let url = Bundle.main.url(forResource: "onboarding_video", withExtension: "mp4") else {
            print("⚠️ onboarding_video.mp4 not found in bundle")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let asset = AVURLAsset(url: url)
            let playerItem = AVPlayerItem(asset: asset)
            let player = AVPlayer(playerItem: playerItem)
            player.isMuted = true
            
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.player = player
                self.playerLayer.player = player
                self.playerLayer.videoGravity = .resizeAspectFill
                self.layer.addSublayer(self.playerLayer)
                self.setNeedsLayout()
                
                // Loop the video seamlessly
                self.loopObserver = NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: player.currentItem,
                    queue: .main
                ) { [weak player] _ in
                    player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
                    player?.play()
                }
                
                player.play()
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
    
    deinit {
        if let observer = loopObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        player?.pause()
        player = nil
    }
}
