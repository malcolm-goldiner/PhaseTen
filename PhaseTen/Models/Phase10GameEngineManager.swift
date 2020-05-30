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
    
    let shared = Phase10GameEngineManager()
    
    let database = CKContainer.default().publicCloudDatabase
    
    var gameReference: CKRecord.Reference?
    
    var gameRecord: CKRecord?
    
    
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
            player.save(record: playerRecord)
        }
    }
    
    private func saveCards(_ deck: CKRecord, withCards cards: [Phase10Card]) {
        cards.forEach { card in
            let cardRecord = CKRecord(recordType: Phase10Card.recordType)
            cardRecord[.description] = card.description
            let deckReference = CKRecord.Reference(record: deck, action: .none)
            cardRecord[Phase10Card.Key.deck] = deckReference
            card.save(record: cardRecord)
        }
    }
    
    public func saveFirstCard() {
        // save first card in discard pile
        if let firstCard = Phase10GameEngine.shared.discardPile.first {
            let record = CKRecord(recordType: Phase10Card.recordType)
            firstCard.save(record: record)
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