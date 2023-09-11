//
//  BaseModel.swift
//  OfflineDownloadWithAVFoundation
//
//  Created by Testpress on 09/09/23.
//

import Foundation
import RealmSwift

public class BaseModel: Object {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var created_at = Date()
    
    func delete(){
        let realm = try! Realm()
        try! realm.write {
            realm.delete(self)
        }
    }
    
    func update(_ attributes: [String: Any]) throws {
        let realm = try! Realm()
        try realm.write {
            for (key, value) in attributes {
                self[key] = value
            }
        }
    }
}
