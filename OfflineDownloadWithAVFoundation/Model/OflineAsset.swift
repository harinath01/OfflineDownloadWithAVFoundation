//
//  Asset.swift
//  OfflineDownloadWithAVFoundation
//
//  Created by Testpress on 04/09/23.
//

import Foundation
import RealmSwift

public class OfflineAsset: BaseModel {
    @Persisted var contentID: String = ""
    @Persisted var srcURL: String = ""
    @Persisted var downloadedPath: String = ""
    @Persisted var downloadedAt = Date()
    @Persisted var status:String = "notStarted"
    @Persisted var isProtected:Bool = false
    @Persisted var key: OfflineKey?
    @Persisted var percentageCompleted: Float = 0.0
    
    public static var manager = ObjectManager<OfflineAsset>()
    
    public var downloadedFileURL: URL? {
        if !self.downloadedPath.isEmpty{
            let baseURL = URL(fileURLWithPath: NSHomeDirectory())
            return baseURL.appendingPathComponent(self.downloadedPath)
        }
        
        return nil
    }
}
