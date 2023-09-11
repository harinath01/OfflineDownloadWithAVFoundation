import UIKit
import AVKit
import RealmSwift

class ViewController: UIViewController {
    @IBOutlet weak var playerContainer: UIView!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var playDownloadedButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressLabel: UILabel!
    
    var playBackURL = URL(string: "https://d384padtbeqfgy.cloudfront.net/transcoded/8eaHZjXt6km/video.m3u8")!
    var player: AVPlayer?
    var playerViewController: AVPlayerViewController?
    private var statusChangeNotificationToken: NotificationToken?
    private var progressChangeNotificationToken: NotificationToken?
    private var offlineAsset: OfflineAsset? {
        didSet {
            updateUIForDownloadingStatus()
            addObserversOnOfflineAsset()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let asset = AVURLAsset(url: self.playBackURL)
        setupDRM(asset)
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        
        addChild(playerViewController!)
        playerContainer.addSubview(playerViewController!.view)
        playerViewController!.view.frame = playerContainer.bounds
        offlineAsset = AssetPersistenceManager.shared.getDownloadedAsset(srcURL: self.playBackURL.absoluteString)
    }
    
    private func setupDRM(_ asset: AVURLAsset){
        ContentKeyManager.shared.contentKeySession.addContentKeyRecipient(asset)
        ContentKeyManager.shared.contentKeyDelegate.setAssetDetails("8eaHZjXt6km", "16b608ba-9979-45a0-94fb-b27c1a86b3c1")
    }
    
    private func addObserversOnOfflineAsset(){
        guard offlineAsset == nil else {
            statusChangeNotificationToken = offlineAsset!.observe(keyPaths: ["status"], {[weak self] change in
                self?.updateUIForDownloadingStatus()
            })
            progressChangeNotificationToken = offlineAsset!.observe(keyPaths: ["percentageCompleted"], {[weak self] change in
                self?.updateProgressBar()
            })
            return
        }
    }
    
    private func updateUIForDownloadingStatus() {
        if let status = offlineAsset?.status {
            switch status {
            case "InProgress":
                title = "Pause"
            case "Paused":
                title = "Resume"
            case "Finished":
                title = "Delete Video"
            default:
                break
            }
        } else {
            title = "Download"
        }
        
        actionButton.setTitle(title, for: .normal)
        playDownloadedButton.isHidden = title != "Delete Video"
        progressView.isHidden = title != "InProgress"
        progressLabel.isHidden = title != "InProgress"
    }
    
    private func updateProgressBar() {
        guard let percentageCompleted = offlineAsset?.percentageCompleted else { return }
        
        progressView.setProgress(percentageCompleted / 100.0, animated: true)
        progressView.isHidden = false
        progressLabel.text = "\(String(format: "%.1f", percentageCompleted))%"
        progressLabel.isHidden = false
    }
    
    @IBAction func startOrPauseDownload(_ sender: Any) {
        guard let asset = offlineAsset else {
            offlineAsset = AssetPersistenceManager.shared.startDownloading(from: playBackURL)
            return
        }
        
        switch asset.status {
        case "InProgress":
            AssetPersistenceManager.shared.pauseDownloadingAsset(asset)
        case "Paused":
            AssetPersistenceManager.shared.resumeDownloadingAsset(asset)
        case "Finished":
            try? AssetPersistenceManager.shared.deleteDownloadedAsset(asset)
            offlineAsset = nil
        default:
            break
        }
    }
    
    @IBAction func playDownloadedVideo(_ sender: Any) {
        if offlineAsset?.downloadedFileURL == nil { return }
        
        let asset = AVURLAsset(url: offlineAsset!.downloadedFileURL!)
        setupDRM(asset)
        if let cache = asset.assetCache, cache.isPlayableOffline {
            let playerItem = AVPlayerItem(asset: asset)
            playerViewController?.player?.replaceCurrentItem(with: playerItem)
            playerViewController?.player?.play()
        }
    }
}
