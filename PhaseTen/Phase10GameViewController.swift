//
//  Phase10GameViewController.swift
//  PhaseTen
//
//  Created by Malcolm Goldiner on 4/6/20.
//  Copyright © 2020 Malcolm Goldiner. All rights reserved.
//

import UIKit
import Combine
import CloudKit


class Phase10GameViewController: UIViewController {
    
    @IBOutlet weak var scoreLabel: UILabel!
    
    @IBOutlet weak var discard: UILabel!
    
    @IBOutlet weak var discardPileCollectionView: UICollectionView!
    
    @IBOutlet weak var potentialCardSetCollectionView: UICollectionView!
    
    @IBOutlet weak var currentHandCollectionView: UICollectionView!
    
    @IBOutlet weak var turnWaitingActivityIndicator: UIActivityIndicatorView!
    
    let database = CKContainer.default().publicCloudDatabase
    
    var needsReload: Bool = false {
        didSet {
            if needsReload {
                reloadCards()
            }
        }
    }
    
    var player: Phase10Player? {
        didSet {
           reloadCards()
        }
    }
    
    var handDataSource: Phase10GameViewDataSource?
    
    var setDataSource: Phase10GameViewDataSource?
    
    var discardDataSource: Phase10GameViewDataSource?
    
    var gameReference: CKRecord.Reference?
    
    var gameRecord: CKRecord?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startGame()
        listenForGameStateChanges()
    }
    
    private func reloadCards() {
        currentHandCollectionView.reloadData()
        potentialCardSetCollectionView.reloadData()
        discardPileCollectionView.reloadData()
    }
    
    private func listenForGameStateChanges() {
        let scoreSubscriber = Subscribers.Assign(object: scoreLabel, keyPath: \.text)
        Phase10GameEngine.shared.$scoresByPlayer.map { [weak self] scoreDict in
            if let player = self?.player,
                let currentScore = scoreDict[player] {
                return "Score: \(currentScore)"
            }
            
            return "Score: 0"
        }.subscribe(scoreSubscriber)
        
        
        Phase10GameEngine.shared.$discardPile.sink { [weak self] _ in
            self?.saveDiscardPile()
        }
        
        Phase10GameEngine.shared.$turnIndex.sink { [weak self] newIndex in
             let player = Phase10GameEngine.shared.players[newIndex]
           
            if self?.player == player {
                self?.turnWaitingActivityIndicator.stopAnimating()
            } else {
                self?.turnWaitingActivityIndicator.startAnimating()
            }
        }
        
        // save first card in discard pile
        if let firstCard = Phase10GameEngine.shared.discardPile.first {
            let record = CKRecord(recordType: Phase10Card.recordType)
            save(record: record, modelObj: firstCard)
        }
        
        let handSubscriber = Subscribers.Assign(object: self, keyPath: \.needsReload)
        player?.$hand.map { !$0.isEmpty }.subscribe(handSubscriber)
        
        let setSubscriber = Subscribers.Assign(object: self, keyPath: \.needsReload)
        player?.$potentialSets.map { !$0.isEmpty }.subscribe(setSubscriber)
        
        let discardSubscriber = Subscribers.Assign(object: self, keyPath: \.needsReload)
        Phase10GameEngine.shared.$discardPile.map { !$0.isEmpty }.subscribe(discardSubscriber)
    }
    
    
    private func startGame() {
        Phase10GameEngine.shared.addPlayer()
        player = Phase10GameEngine.shared.players.first
        handDataSource = Phase10GameViewDataSource(deckType: .hand, game: Phase10GameEngine.shared)
        setDataSource = Phase10GameViewDataSource(deckType: .set, game: Phase10GameEngine.shared)
        discardDataSource = Phase10GameViewDataSource(deckType: .discard, game: Phase10GameEngine.shared)
        persistGame()
        setupCollectionViews()
    }
    
    private func persistGame() {
        gameRecord = CKRecord(recordType: Phase10GameEngine.recordType)
        gameRecord?[.turnIndex] = 0
        save(record: gameRecord!, modelObj: Phase10GameEngine.shared)
        
        let deck = CKRecord(recordType: Phase10Deck.recordType)
        gameReference = CKRecord.Reference(recordID: gameRecord!.recordID, action: .none)
        deck[Phase10Deck.Key.game] = gameReference
        save(record: deck)
        
        saveCards(deck, withCards: Phase10GameEngine.shared.deck.cards)
        savePlayers(inGame: gameReference)
    }
    
    private func saveDiscardPile() {
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
        
        save(record: gameRecord, modelObj: Phase10GameEngine.shared)
    }
    
    private func savePlayers(inGame gameReference: CKRecord.Reference?) {
        Phase10GameEngine.shared.players.forEach { player in
            let playerRecord = CKRecord(recordType: Phase10Player.recordType)
            playerRecord[.name] = player.name
            
            let cardRecords: [CKRecord] = player.hand.compactMap { card in
                let cardRecord = CKRecord(recordType: Phase10Card.recordType)
                cardRecord[.description] = card.description
                save(record: cardRecord, modelObj: card)
                return cardRecord
            }
           
            let cardReferences: [CKRecord.Reference] = cardRecords.compactMap { record in
                return  CKRecord.Reference(record: record, action: .none)
            }
            
            playerRecord[.hand] = cardReferences
            playerRecord[Phase10Player.Key.game] = gameReference
            save(record: playerRecord, modelObj: player)
        }
    }
    
    private func saveCards(_ deck: CKRecord, withCards cards: [Phase10Card]) {
        cards.forEach { card in
            let cardRecord = CKRecord(recordType: Phase10Card.recordType)
            cardRecord[.description] = card.description
            let deckReference = CKRecord.Reference(record: deck, action: .none)
            cardRecord[Phase10Card.Key.deck] = deckReference
            save(record: cardRecord, modelObj: card)
        }
    }
    
    private func save(record: CKRecord, modelObj: Phase10Model? = nil) {
        database.save(record) { (record, error) in
             if let error = error as? CKError,
                error.code.rawValue == 9 {
                print(Phase10Error.auth.rawValue)
            } else if error != nil {
                print(Phase10Error.unknown.rawValue)
             } else {
                print("Saved \(String(describing: record?.recordType))")
                modelObj?.recordID = record?.recordID
            }
        }
    }
    
    private func setupCollectionViews() {
        self.currentHandCollectionView.register(UINib(nibName: CardCollectionViewCell.nibName, bundle: Bundle.main), forCellWithReuseIdentifier: CardCollectionViewCell.reuseIdenitifer)
        
        self.potentialCardSetCollectionView.register(UINib(nibName: CardCollectionViewCell.nibName, bundle: Bundle.main), forCellWithReuseIdentifier: CardCollectionViewCell.reuseIdenitifer)
        
        self.discardPileCollectionView.register(UINib(nibName: CardCollectionViewCell.nibName, bundle: Bundle.main), forCellWithReuseIdentifier: CardCollectionViewCell.reuseIdenitifer)
        
        currentHandCollectionView.delegate = self
        currentHandCollectionView.dataSource = handDataSource
        currentHandCollectionView.dragInteractionEnabled = true
        
        potentialCardSetCollectionView.delegate = self
        potentialCardSetCollectionView.dataSource = setDataSource
        potentialCardSetCollectionView.dragInteractionEnabled = true
        
        currentHandCollectionView.dragDelegate = self
        currentHandCollectionView.dropDelegate = self
        
        potentialCardSetCollectionView.dropDelegate = self
        potentialCardSetCollectionView.dragDelegate = self
        
        discardPileCollectionView.delegate = self
        discardPileCollectionView.dataSource = discardDataSource
        discardPileCollectionView.dragInteractionEnabled = true
        
        discardPileCollectionView.dragDelegate = self
        discardPileCollectionView.dropDelegate = self
        
        reloadCards()
    }
    
}

extension Phase10GameViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("tap not implemented yet")
    }
}

