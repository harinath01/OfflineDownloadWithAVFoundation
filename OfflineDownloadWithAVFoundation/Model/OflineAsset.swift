//
//  Asset.swift
//  OfflineDownloadWithAVFoundation
//
//  Created by Testpress on 04/09/23.
//

import Foundation
import RealmSwift

class OfflineAsset: BaseModel {
    @Persisted var srcURL: String = ""
    @Persisted var downloadedPath: String = ""
    @Persisted var downloadedAt = Date()
    @Persisted var status:String = "notStarted"
    
    public static var manager = ObjectManager<OfflineAsset>()
}
