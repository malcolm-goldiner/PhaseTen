//
//  Phase10GameViewController.swift
//  PhaseTen
//
//  Created by Malcolm Goldiner on 4/6/20.
//  Copyright © 2020 Malcolm Goldiner. All rights reserved.
//

import UIKit
import Combine

class Phase10GameViewController: UIViewController {
    
    @IBOutlet weak var scoreLabel: UILabel!
    
    @IBOutlet weak var discard: UILabel!
    
    @IBOutlet weak var topOfPileCardView: CardView!
    
    @IBOutlet weak var potentialCardSetCollectionView: UICollectionView!
    
    @IBOutlet weak var currentHandCollectionView: UICollectionView!
    
    @IBOutlet weak var takeCardButton: UIButton!
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startGame()
        listenForGameStateChanges()
    }
    
    @IBAction func takeCardPressed(_ sender: UIButton) {
        guard let player = player else {
            return
        }
        
        Phase10GameEngine.shared.pickFromDiscardPile(player: player)
    }
    
    private func reloadCards() {
        currentHandCollectionView.reloadData()
        potentialCardSetCollectionView.reloadData()
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
        
        let discardPileSubscriber = Subscribers.Assign(object: topOfPileCardView, keyPath: \.card)
        Phase10GameEngine.shared.$discardPile.map { $0.last }.subscribe(discardPileSubscriber)
        
        let handSubscriber = Subscribers.Assign(object: self, keyPath: \.needsReload)
        player?.$hand.map { !$0.isEmpty }.subscribe(handSubscriber)
        
        let setSubscriber = Subscribers.Assign(object: self, keyPath: \.needsReload)
        player?.$potentialSets.map { !$0.isEmpty }.subscribe(setSubscriber)
    }
    
    
    private func startGame() {
        Phase10GameEngine.shared.addPlayer()
        player = Phase10GameEngine.shared.players.first
        handDataSource = Phase10GameViewDataSource(deckType: .hand, game: Phase10GameEngine.shared)
        setDataSource = Phase10GameViewDataSource(deckType: .set, game: Phase10GameEngine.shared)
        
        setupCollectionViews()
    }
    
    private func setupCollectionViews() {
        self.currentHandCollectionView.register(UINib(nibName: CardCollectionViewCell.nibName, bundle: Bundle.main), forCellWithReuseIdentifier: CardCollectionViewCell.reuseIdenitifer)
        
        self.potentialCardSetCollectionView.register(UINib(nibName: CardCollectionViewCell.nibName, bundle: Bundle.main), forCellWithReuseIdentifier: CardCollectionViewCell.reuseIdenitifer)
        
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
        
        reloadCards()
    }
    
}

extension Phase10GameViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let dataSource = collectionView.dataSource as? Phase10GameViewDataSource,
            dataSource.deckType == .hand,
            let card = dataSource.cardAt(indexPath),
            let player = player else {
            return
        }
        
        Phase10GameEngine.shared.discardCard(card, player: player)
        currentHandCollectionView.reloadData()
    }
}

