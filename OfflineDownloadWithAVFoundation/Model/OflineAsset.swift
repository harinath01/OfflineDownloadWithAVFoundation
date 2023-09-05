//
//  Asset.swift
//  OfflineDownloadWithAVFoundation
//
//  Created by Testpress on 04/09/23.
//

import Foundation
import RealmSwift

class OfflineAsset: Object {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var srcURL: String = ""
    @Persisted var downloadedPath: String = ""
    @Persisted var downloadedAt = Date()
    @Persisted var status:String = "InProgress"
    
    convenience init(srcURL:String, downloadedPath: String) {
        self.init()
        self.srcURL = srcURL
        self.downloadedPath = downloadedPath
    }
    
    func save() {
        let realm = try! Realm()
        try! realm.write {
            realm.add(self, update: .modified)
        }
    }
    
    func delete(){
        let realm = try! Realm()
        try! realm.write {
            realm.delete(self)
        }
    }
    
    public static var manager = OfflineAssetManager()
}

class OfflineAssetManager {
    let realm = try! Realm()
    
    func create(srcURL: String, downloadedPath: String) -> OfflineAsset{
        let offlineAsset = OfflineAsset(srcURL: srcURL, downloadedPath: downloadedPath)
        try! realm.write {
            realm.add(offlineAsset)
        }
        
        return offlineAsset
    }
    
    func get(srcURL: String) throws -> OfflineAsset {
        let matchingAssets = realm.objects(OfflineAsset.self).filter("srcURL == %@", srcURL)
        guard let asset = matchingAssets.first else {
            throw ModelError.objectDoesNotExist
        }
        
        if matchingAssets.count > 1 {
            throw ModelError.multipleObjectsReturned
        }
        
        return asset
    }
    
    func filter(predicate: NSPredicate) -> Results<OfflineAsset> {
        return realm.objects(OfflineAsset.self).filter(predicate)
    }
}

enum ModelError: Error {
    case multipleObjectsReturned
    case objectDoesNotExist
}



