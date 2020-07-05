//
//  Phase10GameEngineManager.swift
//  PhaseTen
//
//  Created by Malcolm Goldiner on 5/9/20.
//  Copyright © 2020 Malcolm Goldiner. All rights reserved.
//

import UIKit
import Combine
import CloudKit

class Phase10GameEngineManager {
    
    static let shared = Phase10GameEngineManager()
    
    let database = CKContainer.default().publicCloudDatabase
    
    var gameReference: CKRecord.Reference?
    
    var gameRecord: CKRecord?
    
    private var isOriginatingUser: Bool {
        return gameRecord?.creatorUserRecordID?.recordName == CKCurrentUserDefaultName
    }
    
    var areCreatingNewGame = false
    
    var isGameOwner: Bool {
        return areCreatingNewGame || isOriginatingUser
    }
    
    /**
        Creates Phase10Game, Phase10Deck, and Phase10Card Entities for all the locally created objects in the shared Game Engine
     
        Warning: This creates a new game object and will replace any recordID already tied to this Phase10Game
     */
    public func persistGame() {
        gameRecord = CKRecord(recordType: Phase10GameEngine.recordType)
        
        guard let gameRecord = gameRecord else {
            return
        }
        
        gameRecord[.turnIndex] = 0
        Phase10GameEngine.shared.save(record: gameRecord)
        
        let deck = CKRecord(recordType: Phase10Deck.recordType)
        gameReference = CKRecord.Reference(recordID: gameRecord.recordID, action: .none)
        deck[Phase10Deck.Key.game] = gameReference
        Phase10Model.save(record: deck)
        
        saveCards(deck, withCards: Phase10GameEngine.shared.deck.cards)
        savePlayers(inGame: gameReference)
    }
    
    public func saveDiscardPile() {
        guard let gameRecord = gameRecord else {
            return
        }
        
        let cardReferences: [CKRecord.Reference] = Phase10GameEngine.shared.discardPile.compactMap { card in
            guard let recordID = card.recordID else {
                return nil
            }
            
            return CKRecord(recordType: Phase10Card.recordType, recordID: recordID)
        }.compactMap { record in
            return  CKRecord.Reference(record: record, action: .none)
        }
        
        gameRecord[.discardPile] = cardReferences
        
        Phase10GameEngine.shared.save(record: gameRecord)
    }
    
    private func savePlayers(inGame gameReference: CKRecord.Reference?) {
        var index = 0
        Phase10GameEngine.shared.players.forEach { player in
            let playerRecord = CKRecord(recordType: Phase10Player.recordType)
            playerRecord[.name] = player.name
            
            let cardRecords: [CKRecord] = player.hand.compactMap { card in
                let cardRecord = CKRecord(recordType: Phase10Card.recordType)
                cardRecord[.description] = card.description
                card.save(record: cardRecord)
                return cardRecord
            }
            
            let cardReferences: [CKRecord.Reference] = cardRecords.compactMap { record in
                return  CKRecord.Reference(record: record, action: .none)
            }
            
            playerRecord[.hand] = cardReferences
            playerRecord[Phase10Player.Key.game] = gameReference
            playerRecord[.index] = index
            player.save(record: playerRecord)
            index += 1
        }
    }
    
    private func saveCards(_ deck: CKRecord, withCards cards: [Phase10Card]) {
        var place = 0
        cards.forEach { card in
            let cardRecord = CKRecord(recordType: Phase10Card.recordType)
            cardRecord[.description] = card.description
            cardRecord[.placeIndex] = place
            let deckReference = CKRecord.Reference(record: deck, action: .none)
            cardRecord[Phase10Card.Key.deck] = deckReference
            card.save(record: cardRecord)
            place += 1
        }
    }
    
    public func listenToScoreChanges(onLabel scoreLabel: UILabel, forPlayer player: Phase10Player) {
        let scoreSubscriber = Subscribers.Assign(object: scoreLabel, keyPath: \.text)
        Phase10GameEngine.shared.$scoresByPlayer.map { scoreDict in
            if let currentScore = scoreDict[player] {
                return "Score: \(currentScore)"
            }
            
            return "Score: 0"
        }.subscribe(scoreSubscriber)
    }
}
