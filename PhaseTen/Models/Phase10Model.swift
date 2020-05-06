//
//  Phase10Model.swift
//  PhaseTen
//
//  Created by Malcolm Goldiner on 5/2/20.
//  Copyright © 2020 Malcolm Goldiner. All rights reserved.
//

import CloudKit

class Phase10Model {
    
    var recordID: CKRecord.ID?
    
}

extension CKRecord {
    subscript(key: Phase10GameEngine.Key) -> Any? {
        get {
            return self[key.rawValue]
        }
        set {
            self[key.rawValue] = newValue as? CKRecordValue
        }
    }
    
    subscript(key: Phase10Card.Key) -> Any? {
        get {
            return self[key.rawValue]
        }
        set {
            self[key.rawValue] = newValue as? CKRecordValue
        }
    }
    
    subscript(key: Phase10Deck.Key) -> Any? {
        get {
            return self[key.rawValue]
        }
        set {
            self[key.rawValue] = newValue as? CKRecordValue
        }
    }
    
    subscript(key: Phase10Player.Key) -> Any? {
        get {
            return self[key.rawValue]
        }
        set {
            self[key.rawValue] = newValue as? CKRecordValue
        }
    }
}

enum Phase10Error: String {
    case auth = "Not signed into iCloud"
    case unknown = "Unknown Error"
}
