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
    
    var gameManager: Phase10GameEngineManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startGame()
        listenForGameStateChanges()
    }
    
    private func reloadCards() {
        currentHandCollectionView.reloadData()
        topPotentialCardSetCollectionView.reloadData()
        bottomPotentialCardSetCollectionView.reloadData()
        discardPileCollectionView.reloadData()
    }
    
    private func listenForGameStateChanges() {
        guard let player = player else {
            return
        }
        gameManager?.listenToScoreChanges(onLabel: scoreLabel, forPlayer: player)
        
        _ = Phase10GameEngine.shared.$discardPile.sink { [weak self] _ in
            self?.gameManager?.saveDiscardPile()
        }
        
        _ = Phase10GameEngine.shared.$turnIndex.sink { [weak self] newIndex in
            let player = Phase10GameEngine.shared.players[newIndex]
            
            if self?.player == player {
                self?.turnWaitingActivityIndicator.stopAnimating()
            } else {
                self?.turnWaitingActivityIndicator.startAnimating()
            }
        }
        
        gameManager?.saveFirstCard()
        
        let handSubscriber = Subscribers.Assign(object: self, keyPath: \.needsReload)
        player.$hand.map { !$0.isEmpty }.subscribe(handSubscriber)
        
        let setSubscriber = Subscribers.Assign(object: self, keyPath: \.needsReload)
        player.$firstPotentialSet.map { !$0.isEmpty }.subscribe(setSubscriber)
        
        let secondSetSubscriber = Subscribers.Assign(object: self, keyPath: \.needsReload)
        player.$secondPotentialSet.map { !$0.isEmpty }.subscribe(secondSetSubscriber)
        
        let discardSubscriber = Subscribers.Assign(object: self, keyPath: \.needsReload)
        Phase10GameEngine.shared.$discardPile.map { !$0.isEmpty }.subscribe(discardSubscriber)
    }

    private func startGame() {
        Phase10GameEngine.shared.addPlayer()
        player = Phase10GameEngine.shared.players.first
        handDataSource = Phase10GameViewDataSource(deckType: .hand, game: Phase10GameEngine.shared)
        setDataSource = Phase10GameViewDataSource(deckType: .set(order: .top), game: Phase10GameEngine.shared)
        secondSetDataSource = Phase10GameViewDataSource(deckType: .set(order: .bottom), game: Phase10GameEngine.shared)
        discardDataSource = Phase10GameViewDataSource(deckType: .discard, game: Phase10GameEngine.shared)
        gameManager?.persistGame()
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

