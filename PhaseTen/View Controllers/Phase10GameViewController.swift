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
    
    @IBOutlet weak var topPotentialCardSetCollectionView: UICollectionView!
    
    @IBOutlet weak var bottomPotentialCardSetCollectionView: UICollectionView!
    
    @IBOutlet weak var topPotentialComboLabel: UILabel!
    
    @IBOutlet weak var bottomPotentialComboLabel: UILabel!
    
    @IBOutlet weak var currentHandCollectionView: UICollectionView!
    
    @IBOutlet weak var turnWaitingActivityIndicator: UIActivityIndicatorView!

    var needsReload: Bool = false {
        didSet {
            if needsReload {
                reloadCards()
                
                if Phase10GameEngine.shared.players[Phase10GameEngine.shared.turnIndex] != player ||
                   Phase10GameEngine.shared.players.count != Phase10GameEngine.shared.expectedNumberOfPlayers {
                    turnWaitingActivityIndicator.startAnimating()
                }
            }
        }
    }
    
    var reactiveUpdatedSets: [[Phase10Card]]? = nil {
        didSet {
            if reactiveUpdatedSets?.filter({ !$0.isEmpty }).isEmpty == false,
                let player = player {
                validatePhase(withSets: reactiveUpdatedSets!, forPlayer: player)
            }
        }
    }
    
    var player: Phase10Player? = Phase10GameEngine.shared.localPlayer {
        didSet {
            reloadCards()
        }
    }
    
    var handDataSource: Phase10GameViewDataSource?
    
    var setDataSource: Phase10GameViewDataSource?
    
    var secondSetDataSource: Phase10GameViewDataSource?
    
    var discardDataSource: Phase10GameViewDataSource?
    
    var gameManager = Phase10GameEngineManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startGame()
        listenForGameStateChanges()
        listenForDatabaseChanges()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        needsReload = true 
    }
    
    private func reloadCards() {
        DispatchQueue.main.async { [weak self] in
            self?.currentHandCollectionView.reloadData()
            self?.topPotentialCardSetCollectionView.reloadData()
            self?.bottomPotentialCardSetCollectionView.reloadData()
            self?.discardPileCollectionView.reloadData()
        }
    }
    
    private func listenForGameStateChanges() {
        guard let player = player else {
            return
        }
        
        gameManager.listenToScoreChanges(onLabel: scoreLabel, forPlayer: player)
        
        if gameManager.isGameOwner {
            _ = Phase10GameEngine.shared.$discardPile.sink { [weak self] _ in
                self?.gameManager.saveDiscardPile()
            }
        }
        
        // seems to run on first launch only
        _ = Phase10GameEngine.shared.$turnIndex.sink { [weak self] newIndex in
            let player = Phase10GameEngine.shared.players[newIndex]
            
            if self?.player == player {
                self?.turnWaitingActivityIndicator.stopAnimating()
            } else {
                self?.turnWaitingActivityIndicator.startAnimating()
            }
        }
        
        let handSubscriber = Subscribers.Assign(object: self, keyPath: \.needsReload)
        player.$hand.map { !$0.isEmpty }.subscribe(handSubscriber)
        
        let setSubscriber = Subscribers.Assign(object: self, keyPath: \.needsReload)
        player.$firstPotentialSet.map { !$0.isEmpty }.subscribe(setSubscriber)

        let secondSetSubscriber = Subscribers.Assign(object: self, keyPath: \.needsReload)
        player.$secondPotentialSet.map { !$0.isEmpty }.subscribe(secondSetSubscriber)
        
        let validationSubscriber = Subscribers.Assign(object: self, keyPath: \.reactiveUpdatedSets)
        player.$firstPotentialSet.combineLatest(player.$secondPotentialSet).map { [$0, $1] }.subscribe(validationSubscriber)
        
        let discardSubscriber = Subscribers.Assign(object: self, keyPath: \.needsReload)
        Phase10GameEngine.shared.$discardPile.map { !$0.isEmpty }.subscribe(discardSubscriber)
        
        let turnSub = Subscribers.Assign(object: self, keyPath: \.needsReload)
        Phase10GameEngine.shared.$turnIndex.map { Phase10GameEngine.shared.players[$0] != player }.subscribe(turnSub)
        
        let inviteSub = Subscribers.Assign(object: self, keyPath: \.needsReload)
        Phase10GameEngine.shared.$expectedNumberOfPlayers.map { $0 != nil }.subscribe(inviteSub)
        
        let phaseSub = Subscribers.Assign(object: topPotentialComboLabel, keyPath: \.text)
        player.$phase.map { String($0?.description().split(separator: "-").first ?? "") }.subscribe(phaseSub)
        
        
        let phaseSub2 = Subscribers.Assign(object: bottomPotentialComboLabel, keyPath: \.text)
        player.$phase.map { String($0?.description().split(separator: "-").last ?? "") }.subscribe(phaseSub2)
    }
    
    private func listenForDatabaseChanges() {
        guard let gameRecord = Phase10GameEngineManager.shared.gameRecord,
              let deckRecordID = Phase10GameEngine.shared.deck.recordID else {
            return
        }
        
        UIApplication.shared.registerForRemoteNotifications()
        
        subscription(for: Phase10GameEngine.recordType)
        
        let gamePredicate = NSPredicate(format: "game == %@", gameRecord)
        let deckRecord = CKRecord(recordType: Phase10Deck.recordType, recordID: deckRecordID)
        
        subscription(for: Phase10Card.recordType, with: NSPredicate(format: "deck == %@", deckRecord))
        subscription(for: Phase10Player.recordType, with: gamePredicate)
        subscription(for: Phase10Deck.recordType, with: gamePredicate)
    }
    
    private func subscription(for recordType: String, with predicate: NSPredicate = NSPredicate(value: true)) {
        let subscription = CKQuerySubscription(recordType: recordType,
                                               predicate: predicate,
                                               options: [.firesOnRecordUpdate])
        
        let info = CKSubscription.NotificationInfo()
        info.alertLocalizationKey = "\(recordType)_changed_alert"
        subscription.notificationInfo = info
                                                
        
        saveSubscription(subscription)
    }
    
    private func saveSubscription(_ subscription: CKQuerySubscription) {
        CKContainer.default().publicCloudDatabase.save(subscription) { [weak self] savedSubscription, error in
            guard let savedSubscription = savedSubscription, error == nil else {
                // awesome error handling
                return
            }
            
            // subscription saved successfully
            // (probably want to save the subscriptionID in user defaults or something)
        }
    }
    
    
    
    private func validatePhase(withSets combinedSets: [[Phase10Card]], forPlayer player: Phase10Player) {
        let cleared = Phase10GameEngine.shared.validatePhase(for: player, playedCards: combinedSets)
        
        if cleared {
            Phase10GameEngine.shared.movePlayerToNextPhase(player)
            
            let alertController = UIAlertController(title: "Phase Cleared!", message: "You've moved onto the next Phase", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Great!", style: .default, handler: { _ in
                alertController.dismiss(animated: true, completion: nil)
            }))
            
            present(alertController, animated: true, completion: nil)
        }
    }
    
    private func startGame() {
        // what if the players are still being loaded in?
        Phase10GameEngine.shared.addPlayer()
        
        handDataSource = Phase10GameViewDataSource(deckType: .hand, game: Phase10GameEngine.shared)
        setDataSource = Phase10GameViewDataSource(deckType: .set(order: .top), game: Phase10GameEngine.shared)
        secondSetDataSource = Phase10GameViewDataSource(deckType: .set(order: .bottom), game: Phase10GameEngine.shared)
        discardDataSource = Phase10GameViewDataSource(deckType: .discard, game: Phase10GameEngine.shared)
       
        
        // If we are joining a game already in progress we don't need to do this
        if gameManager.isGameOwner == true {
            gameManager.persistGame()
            
            // This could come through before it has been saved
            if let name = gameManager.gameRecord?.recordID.recordName {
                UIPasteboard.general.string = name
            }
            
            DispatchQueue.main.async { [weak self] in
                let clipboardAlert = UIAlertController(title: "Game Info Copied",
                                  message: "Game ID coppied to clipboard, send this to all the people who you want to join!",
                                  preferredStyle: .alert)
                
                clipboardAlert.addTextField { (textField) in
                    textField.placeholder = "2"
                    textField.keyboardType = .numberPad
                }

                clipboardAlert.addAction(UIAlertAction(title: "Enter", style: .default, handler: { [weak clipboardAlert] (_) in
                    guard let enteredText = clipboardAlert?.textFields?.first?.text,
                          let numPlayers = Int(enteredText) else {
                        return
                    }
                    
                    Phase10GameEngine.shared.expectedNumberOfPlayers = numPlayers
                }))

                self?.present(clipboardAlert, animated: true, completion: nil)
            }
        }
        
        setupCollectionViews()
    }
    
    private func setupCollectionViews() {
        self.currentHandCollectionView.register(UINib(nibName: CardCollectionViewCell.nibName, bundle: Bundle.main), forCellWithReuseIdentifier: CardCollectionViewCell.reuseIdenitifer)
        
        self.bottomPotentialCardSetCollectionView.register(UINib(nibName: CardCollectionViewCell.nibName, bundle: Bundle.main), forCellWithReuseIdentifier: CardCollectionViewCell.reuseIdenitifer)
        
        self.topPotentialCardSetCollectionView.register(UINib(nibName: CardCollectionViewCell.nibName, bundle: Bundle.main), forCellWithReuseIdentifier: CardCollectionViewCell.reuseIdenitifer)
        
        self.discardPileCollectionView.register(UINib(nibName: CardCollectionViewCell.nibName, bundle: Bundle.main), forCellWithReuseIdentifier: CardCollectionViewCell.reuseIdenitifer)
        
        currentHandCollectionView.delegate = self
        currentHandCollectionView.dataSource = handDataSource
        currentHandCollectionView.dragInteractionEnabled = true
        
        bottomPotentialCardSetCollectionView.delegate = self
        bottomPotentialCardSetCollectionView.dataSource = secondSetDataSource
        bottomPotentialCardSetCollectionView.dragInteractionEnabled = true
        
        topPotentialCardSetCollectionView.delegate = self
        topPotentialCardSetCollectionView.dataSource = setDataSource
        topPotentialCardSetCollectionView.dragInteractionEnabled = true
        
        currentHandCollectionView.dragDelegate = self
        currentHandCollectionView.dropDelegate = self
        
        bottomPotentialCardSetCollectionView.dropDelegate = self
        bottomPotentialCardSetCollectionView.dragDelegate = self
        
        topPotentialCardSetCollectionView.dropDelegate = self
        topPotentialCardSetCollectionView.dragDelegate = self
        
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

