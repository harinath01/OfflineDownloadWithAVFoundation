import Foundation
import AVFoundation
import RealmSwift

public final class AssetPersistenceManager: NSObject {
    static public let shared = AssetPersistenceManager()
    
    private var assetDownloadURLSession: AVAssetDownloadURLSession!
    private var activeDownloadsMap = [AVAssetDownloadTask: OfflineAsset]()
    private let realm = try! Realm()
    
    private override init() {
        super.init()
        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: "com.tpstreams.downloadSession")
        assetDownloadURLSession = AVAssetDownloadURLSession(
            configuration: backgroundConfiguration,
            assetDownloadDelegate: self,
            delegateQueue: OperationQueue.main
        )
    }
    
    public func getDownloadedAsset(srcURL: String) -> OfflineAsset? {
        let predicate = NSPredicate(format: "srcURL == %@ AND status == %@", srcURL, "Finished")
        return OfflineAsset.manager.filter(predicate: predicate).first
    }
    
    public func startDownloading(from srcURL: URL) -> OfflineAsset? {
        let asset = createAVURLAsset(from: srcURL)
        
        guard let task = assetDownloadURLSession.makeAssetDownloadTask(
            asset: asset,
            assetTitle: "video",
            assetArtworkData: nil,
            options: [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: 265_000]
        ) else {
            return nil
        }
        
        let offlineAsset = try! OfflineAsset.manager.create(["srcURL": srcURL.absoluteString])
        activeDownloadsMap[task] = offlineAsset
        task.resume()
        return offlineAsset
    }
    
    public func deleteDownloadedAsset(_ offlineAsset: OfflineAsset) throws {
        guard offlineAsset.status == "Finished" else {
            fatalError("Video not downloaded completely yet, try to use cancel")
        }
        
        try FileManager.default.removeItem(at: offlineAsset.downloadedFileURL!)
        offlineAsset.delete()
    }
    
    public func pauseDownloadingAsset(_ offlineAsset: OfflineAsset) {
        if let task = activeDownloadsMap.first(where: { $0.value == offlineAsset })?.key {
            task.suspend()
            try! offlineAsset.update(["status": "Paused"])
        }
    }
    
    public func resumeDownloadingAsset(_ offlineAsset: OfflineAsset) {
        if let task = activeDownloadsMap.first(where: { $0.value == offlineAsset })?.key {
            if task.state != .running {
                task.resume()
                try! offlineAsset.update(["status": "InProgress"])
            }
        }
    }
    
    public func cancelDownload(_ offlineAsset: OfflineAsset) {
        if let task = activeDownloadsMap.first(where: { $0.value == offlineAsset })?.key {
            task.cancel()
            activeDownloadsMap.removeValue(forKey: task)
            offlineAsset.delete()
        }
    }
    
    public func getListOfDownloads() -> Results<OfflineAsset> {
        return realm.objects(OfflineAsset.self)
    }
    
    private func createAVURLAsset(from srcURL: URL) -> AVURLAsset {
        let asset = AVURLAsset(url: srcURL)
        ContentKeyManager.shared.contentKeySession.addContentKeyRecipient(asset)
        ContentKeyManager.shared.contentKeyDelegate.setAssetDetails("8eaHZjXt6km", "16b608ba-9979-45a0-94fb-b27c1a86b3c1")
        return asset
    }
}

extension AssetPersistenceManager: AVAssetDownloadDelegate {
    public func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        guard let offlineAsset = activeDownloadsMap[assetDownloadTask] else { return }
        
        try! offlineAsset.update(["downloadedPath": location.relativePath])
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard error != nil else {
            guard let assetDownloadTask = task as? AVAssetDownloadTask,
                  let offlineAsset = activeDownloadsMap[assetDownloadTask] else { return }
            
            try! offlineAsset.update(["status": "Finished"])
            activeDownloadsMap.removeValue(forKey: assetDownloadTask)
            return
        }
    }
    
    public func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        guard let offlineAsset = activeDownloadsMap[assetDownloadTask] else { return }
        
        var percentageComplete = 0.0
        for value in loadedTimeRanges {
            let loadedTimeRange = value.timeRangeValue
            percentageComplete += loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
        }
        
        try! offlineAsset.update(["status": "InProgress", "percentageCompleted": percentageComplete * 100])
    }
}
