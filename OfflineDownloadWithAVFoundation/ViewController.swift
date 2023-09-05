import UIKit
import AVKit

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
    private var downloadingStatus: DownloadingStatus = .notStarted {
        didSet {
            updateUIForDownloadingStatus()
        }
    }
    private var downloadedPath: URL?
    
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
    }
    
    private func updateUIForDownloadingStatus() {
        switch downloadingStatus {
        case .notStarted:
            title = "Download"
        case .started:
            title = "Pause"
        case .paused:
            title = "Resume"
        case .finished:
            title = "Delete Video"
            playDownloadedButton.isHidden = false
            progressView.isHidden = true
            progressLabel.isHidden = true
        }
        actionButton.setTitle(title, for: .normal)
    }
    
    @IBAction func startOrPauseDownload(_ sender: Any) {
        switch downloadingStatus {
        case .notStarted, .paused:
            startOrResumeDownloading()
        case .started:
            pauseDownloading()
        case .finished:
            deleteDownloadedVideo()
        }
    }
    
    private func startOrResumeDownloading() {
        initializeDownloadSession()
        initializeDownloadTask()
        downloadTask!.resume()
        downloadingStatus = .started
    }
    
    private func pauseDownloading() {
        if downloadTask?.state == .running {
            downloadTask?.cancel()
            downloadingStatus = .paused
        }
    }
    
    private func deleteDownloadedVideo() {
        // Implement delete functionality here
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
        if downloadedPath == nil {
            return
        }     
        
        let playerItem = AVPlayerItem(url: downloadedPath!)
        playerViewController?.player?.replaceCurrentItem(with: playerItem)
        playerViewController?.player?.play()
    }
}


extension ViewController: AVAssetDownloadDelegate {
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        self.downloadedPath = location
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard error != nil else {
            self.downloadingStatus = .finished
            return
        }
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        self.progressView.isHidden = false
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

enum DownloadingStatus {
    case notStarted
    case started
    case paused
    case finished
}
