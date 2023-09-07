import UIKit
import AVKit
import RealmSwift

class ViewController: UIViewController {
    @IBOutlet weak var playerContainer: UIView!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var playDownloadedButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressLabel: UILabel!
    
    var playBackURL = URL(fileURLWithPath: "https://d384padtbeqfgy.cloudfront.net/transcoded/8r65J7EY6NP/video.m3u8")
    var player: AVPlayer?
    var playerViewController: AVPlayerViewController?
    private let configuration = URLSessionConfiguration.background(withIdentifier: "com.tpstreams.downloadSession")
    private var downloadSession: AVAssetDownloadURLSession?
    private var downloadTask: AVAssetDownloadTask?
    private var realmNotificationToken: NotificationToken?
    private var offlineAsset: OfflineAsset? {
        didSet {
            if let status = offlineAsset?.status {
                if status == "Finished" {
                    updateUIForDownloadingStatus()
                } else {
                    addObserversOnOfflineAsset()
                }
            }
        }
    }
    
    private var downloadedFileURL: URL?{
        if offlineAsset?.downloadedPath != nil{
            let baseURL = URL(fileURLWithPath: NSHomeDirectory())
            return baseURL.appendingPathComponent(offlineAsset!.downloadedPath)
        }
        
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlayerView()
    }
    
    private func setupPlayerView() {
        let asset = AVURLAsset(url: self.playBackURL)
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        
        addChild(playerViewController!)
        playerContainer.addSubview(playerViewController!.view)
        playerViewController!.view.frame = playerContainer.bounds
        offlineAsset = getOfflineAsset()
    }
    
    private func getOfflineAsset() -> OfflineAsset? {
        let predicate = NSPredicate(format: "srcURL == %@ AND status == %@", self.playBackURL.absoluteString, "Finished")
        return OfflineAsset.manager.filter(predicate: predicate).first
    }
    
    private func addObserversOnOfflineAsset(){
        realmNotificationToken = self.offlineAsset!.observe(keyPaths: ["status"], {[weak self] change in
            self?.updateUIForDownloadingStatus()
        })
    }
    
    private func updateUIForDownloadingStatus() {
        guard let status = offlineAsset?.status else { return }
        
        switch status {
        case "InProgress":
            title = "Pause"
        case "Paused":
            title = "Resume"
        case "Finished":
            title = "Delete Video"
            playDownloadedButton.isHidden = false
            progressView.isHidden = true
            progressLabel.isHidden = true
        default:
            title = "Download Video"
        }
        
        actionButton.setTitle(title, for: .normal)
    }
    
    @IBAction func startOrPauseDownload(_ sender: Any) {
        if offlineAsset == nil {
            offlineAsset = OfflineAsset.manager.create(srcURL: self.playBackURL.absoluteString, downloadedPath: "")
            startOrResumeDownloading()
            return
        }
        
        guard let status = offlineAsset?.status else { return }
        
        switch status {
        case "InProgress":
            pauseDownloading()
        case "Paused":
            startOrResumeDownloading()
        case "Finished":
            deleteDownloadedVideo()
        default:
            break
        }
    }
    
    private func startOrResumeDownloading() {
        initializeDownloadSession()
        initializeDownloadTask()
        downloadTask!.resume()
        progressView.isHidden = false
        progressLabel.isHidden = false
    }
    
    private func pauseDownloading() {
        if downloadTask?.state == .running {
            downloadTask?.suspend()
            offlineAsset?.set(\.status, value: "Paused")
        }
    }
    
    private func deleteDownloadedVideo() {
        deleteVideoFromStorage()
        offlineAsset?.delete()
        offlineAsset = nil
        actionButton.setTitle("Download", for: .normal)
        playDownloadedButton.isHidden = true
    }
    
    private func deleteVideoFromStorage() {
        if downloadedFileURL == nil{ return }
        
        do {
            try FileManager.default.removeItem(at: downloadedFileURL!)
        } catch {
            print("Failed to delete the video from storage")
        }
        
    }
    
    private func initializeDownloadSession() {
        if self.downloadSession == nil {
            downloadSession = AVAssetDownloadURLSession(configuration: configuration, assetDownloadDelegate: self, delegateQueue: OperationQueue.main)
        }
    }
    
    private func initializeDownloadTask() {
        if self.downloadTask == nil {
            downloadTask = downloadSession?.makeAssetDownloadTask(asset: AVURLAsset(url: URL(string: "https://d384padtbeqfgy.cloudfront.net/transcoded/AeDsCzqB5Td/video.m3u8")!),
                                                                  assetTitle: "video",
                                                                  assetArtworkData: nil,
                                                                  options: nil)
        }
    }
    
    @IBAction func playDownloadedVideo(_ sender: Any) {
        let asset = AVURLAsset(url: self.downloadedFileURL!)
        if let cache = asset.assetCache, cache.isPlayableOffline {
            let playerItem = AVPlayerItem(asset: asset)
            playerViewController?.player?.replaceCurrentItem(with: playerItem)
            playerViewController?.player?.play()
        }
    }
}


extension ViewController: AVAssetDownloadDelegate {
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        offlineAsset?.set(\.downloadedPath, value: location.relativePath)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard error != nil else {
            offlineAsset?.set(\.status, value: "Finished")
            return
        }
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        offlineAsset?.set(\.status, value: "InProgress")
        var percentageComplete = 0.0
        
        for value in loadedTimeRanges {
            let loadedTimeRange = value.timeRangeValue
            percentageComplete += loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
        }
        
        progressView.setProgress(Float(percentageComplete), animated: true)
        
        let downloadCompletedString = String(format: "%.1f", percentageComplete * 100)
        
        print("\(downloadCompletedString)% downloaded")
        progressLabel.text = "\(downloadCompletedString)%"
    }
}
