//
//  OfflineKey.swift
//  OfflineDownloadWithAVFoundation
//
//  Created by Testpress on 09/09/23.
//

import Foundation
import RealmSwift

class OfflineKey: BaseModel {
    @Persisted var storedPath: String = ""
    @Persisted var valid_until = Date()
    @Persisted var status:String = "Requested"
    
    public static var manager = ObjectManager<OfflineKey>()
}
