import Foundation
import AVFoundation
import RealmSwift

public final class AssetPersistenceManager: NSObject {
    static public let shared = AssetPersistenceManager()
    
    private var assetDownloadURLSession: AVAssetDownloadURLSession!
    private var activeDownloadsMap = [AVAssetDownloadTask: OfflineAsset]()
    private let realm = try! Realm()
    var contentKeySession: AVContentKeySession!
    var contentKeyDelegate: ContentKeyDelegate!
    let contentKeyDelegateQueue = DispatchQueue(label: "com.tpstreams.iOSPlayerSDK.ContentKeyDelegateQueue")
    
    
    
    private override init() {
        super.init()
        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: "com.tpstreams.downloadSession")
        assetDownloadURLSession = AVAssetDownloadURLSession(
            configuration: backgroundConfiguration,
            assetDownloadDelegate: self,
            delegateQueue: OperationQueue.main
        )
        contentKeySession = AVContentKeySession(keySystem: .fairPlayStreaming)
        contentKeyDelegate = ContentKeyDelegate()
        contentKeySession.setDelegate(contentKeyDelegate, queue: contentKeyDelegateQueue)
    }
    
    public func getDownloadedAsset(srcURL: String) -> OfflineAsset? {
        let predicate = NSPredicate(format: "srcURL == %@ AND status == %@", srcURL, "Finished")
        return OfflineAsset.manager.filter(predicate: predicate).first
    }
    
    public func startDownloading(from srcURL: URL) -> OfflineAsset? {
        let asset = AVURLAsset(url: srcURL)
        
        guard let task = assetDownloadURLSession.makeAssetDownloadTask(
            asset: asset!,
            assetTitle: "video",
            assetArtworkData: nil,
            options: [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: 265_000]
        ) else {
            return nil
        }
        
        let offlineAsset = try! OfflineAsset.manager.create(["srcURL": srcURL.absoluteString, "contentID": "f6018f9642234d83829378c8f682050a"])
        activeDownloadsMap[task] = offlineAsset
        task.resume()
        requestPersistentKey(offlineAsset)
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
    
    private func requestPersistentKey(_ offlineasset: OfflineAsset) {
        if let key = offlineasset.key {
            try! key.update(["status": "Requested"])
        } else {
            let keyData: [String: Any] = ["status": "Requested"]
            let newKey = try! OfflineKey.manager.create(keyData)
            try! offlineasset.update(["key": newKey])
        }
        
        contentKeyDelegate.setAssetDetails("7Hs5bmMEuSE", "1153bdf8-cd99-4924-b4a2-54deeec214d8")
        contentKeySession.processContentKeyRequest(
            withIdentifier: "skd://\(offlineasset.contentID)",
            initializationData: nil,
            options: nil
        )
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
