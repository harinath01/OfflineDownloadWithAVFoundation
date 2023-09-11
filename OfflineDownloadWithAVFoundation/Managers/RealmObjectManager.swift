//
//  RealmObjectManager.swift
//  OfflineDownloadWithAVFoundation
//
//  Created by Testpress on 11/09/23.
//

import Foundation
import RealmSwift

public class ObjectManager<T: Object> {
    let realm = try! Realm()
    
    func create(_ attributes: [String: Any]) throws -> T {
        let object = T()
        try self.raiseErrorIfInvalidAttributePassed(object, attributes)
        
        for (key, value) in attributes {
            object[key] = value
        }
        
        try realm.write {
            realm.add(object)
        }
        
        return object
    }
    
    
    func get(where attributeKey: String, isEqualTo attributeValue: String) throws -> T? {
        let predicate = NSPredicate(format: "%K == %@", attributeKey, attributeValue)
        let matchingObjects = realm.objects(T.self).filter(predicate)
        
        guard let object = matchingObjects.first else {
            throw ModelError.objectDoesNotExist
        }
        
        if matchingObjects.count > 1 {
            throw ModelError.multipleObjectsReturned
        }
        
        return object
    }
    
    func update(_ object: T, with attributes: [String: Any]) throws {
        try self.raiseErrorIfInvalidAttributePassed(object, attributes)
        
        try realm.write {
            for (key, value) in attributes {
                object[key] = value
            }
        }
    }
    
    func filter(predicate: NSPredicate) -> Results<T> {
        return realm.objects(T.self).filter(predicate)
    }
    
    private func raiseErrorIfInvalidAttributePassed(_ object: T, _ attributes: [String: Any]) throws {
        for (key, _) in attributes {
            if object[key] == nil {
                throw ModelError.invalidAttribute(attributeName: key)
            }
        }
    }
}


enum ModelError: Error {
    case multipleObjectsReturned
    case objectDoesNotExist
    case invalidAttribute(attributeName: String)
}
