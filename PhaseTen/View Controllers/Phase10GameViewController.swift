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
                
                if Phase10GameEngine.shared.players[Phase10GameEngine.shared.turnIndex] != player {
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
    
    var player: Phase10Player? {
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
        
        if gameManager.isOriginatingUser {
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
        
        if gameManager.isOriginatingUser {
             gameManager.saveFirstCard()
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
    }
    
    private func validatePhase(withSets combinedSets: [[Phase10Card]], forPlayer player: Phase10Player) {
        let cleared = Phase10GameEngine.shared.validatePhase(for: player, playedCards: combinedSets)
        
        if cleared {
            Phase10GameEngine.shared.movePlayerToNextPhase(player)
            
            let alertController = UIAlertController(title: "Phase Cleared!", message: "You've moved onto the next Phase", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Great!", style: .default, handler: { [weak self] _ in
                alertController.dismiss(animated: true, completion: nil)
            }))
            
            present(alertController, animated: true, completion: nil)
        }
    }

    private func startGame() {
        // what if the players are still being loaded in?
        Phase10GameEngine.shared.addPlayer()
        player = Phase10GameEngine.shared.players.first(where: { $0.isGameOwner })
        handDataSource = Phase10GameViewDataSource(deckType: .hand, game: Phase10GameEngine.shared)
        setDataSource = Phase10GameViewDataSource(deckType: .set(order: .top), game: Phase10GameEngine.shared)
        secondSetDataSource = Phase10GameViewDataSource(deckType: .set(order: .bottom), game: Phase10GameEngine.shared)
        discardDataSource = Phase10GameViewDataSource(deckType: .discard, game: Phase10GameEngine.shared)
       
        
        // If we are joining a game already in progress we don't need to do this
        if gameManager.isOriginatingUser == true {
            gameManager.persistGame()
        }
        
        setupCollectionViews()
        
        if let phase = player?.phase {
            let splitDesc = phase.description().split(separator: " ")
            topPotentialComboLabel.text = splitDesc.first?.description
            bottomPotentialComboLabel.text = splitDesc.last?.description
        }
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

