//
//  Phase10GameViewController.swift
//  PhaseTen
//
//  Created by Malcolm Goldiner on 4/6/20.
//  Copyright © 2020 Malcolm Goldiner. All rights reserved.
//

import UIKit
import Combine

enum DeckType {
    case hand
    case set
}

class Phase10GameViewDataSource: NSObject, UICollectionViewDataSource {
    
    private var player: Phase10Player?
    
    var deckType: DeckType
    
    init(deckType: DeckType, game: Phase10GameEngine) {
        self.deckType = deckType
        self.player = game.players.first
    }
    
    func cardAt(_ indexPath: IndexPath) -> Phase10Card? {
        if deckType == .hand {
            return player?.hand[indexPath.row]
        } else {
            return player?.potentialSets[indexPath.row]
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if deckType == .set {
            return player?.potentialSets.count ?? 0
        } else {
            return player?.hand.count ?? 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CardCollectionViewCell.reuseIdenitifer, for: indexPath) as? CardCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        cell.card = cardAt(indexPath)
        
        return cell
    }
    
    func addCard(_ card: Phase10Card, atIndexPath indexPath: IndexPath) {
        switch deckType {
        case .set:
            player?.potentialSets.append(card)
        case .hand:
            player?.hand.append(card)
        }
    }
    
    func moveCard(at sourceIndex: Int, to destinationIndex: Int?) {
        guard sourceIndex != destinationIndex else { return }
        
        if let card = cardAt(IndexPath(row: sourceIndex, section: 0)) {
            switch deckType {
            case .hand:
                player?.potentialSets.append(card)
                player?.hand.remove(at: sourceIndex)
            case .set:
                player?.hand.append(card)
                player?.potentialSets.remove(at: sourceIndex)
                
            }
        }
    }
    
    func acceptDraggedCard(_ card: Phase10Card, to destinationIndex: Int?) {
        guard let player = player else {
            return
        }
        
        switch deckType {
        case .set:
            player.potentialSets.append(card)
            player.hand = player.hand.filter { $0 != card }
        case .hand:
            player.hand.append(card)
            player.potentialSets = player.potentialSets.filter { $0 != card }
        }
    }
    
    
}

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
                currentHandCollectionView.reloadData()
                potentialCardSetCollectionView.reloadData()
            }
        }
    }
    
    var player: Phase10Player? {
        didSet {
            currentHandCollectionView.reloadData()
            potentialCardSetCollectionView.reloadData()
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
        self.currentHandCollectionView!.register(UINib(nibName: CardCollectionViewCell.nibName, bundle: Bundle.main), forCellWithReuseIdentifier: CardCollectionViewCell.reuseIdenitifer)
        
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
        
        potentialCardSetCollectionView.reloadData()
        currentHandCollectionView.reloadData()
    }
    
}

extension Phase10GameViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let dataSource = collectionView.dataSource as? Phase10GameViewDataSource,
            let card = dataSource.cardAt(indexPath),
            let player = player else {
            return
        }
        
        Phase10GameEngine.shared.discardCard(card, player: player)
        currentHandCollectionView.reloadData()
    }
}

extension Phase10GameViewController: UICollectionViewDropDelegate, UICollectionViewDragDelegate {
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            destinationIndexPath = IndexPath(
                item: collectionView.numberOfItems(inSection: 0),
                section: 0)
        }
        
        let item = coordinator.items[0]
        cardFrom(item.dragItem, collectionView: collectionView, destinationIndexPath: destinationIndexPath)
        
        switch coordinator.proposal.operation
        {
        case .move:
            coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
        default:
            return
        }
    }
    
    private func cardFrom(_ dragItem: UIDragItem, collectionView: UICollectionView, destinationIndexPath: IndexPath) {
        dragItem.itemProvider.loadObject(ofClass: NSString.self) { string, error in
            if let string = string as? String {
                
                let splitCardString = string.split(separator: " ")
                
                let color = splitCardString.first!.description
                if let parsedType = Int(splitCardString.last!.description),
                    let type = Phase10CardType(rawValue: parsedType) {
                    
                    var realColor: UIColor
                    
                    if color == "red" {
                        realColor = .red
                    } else if color == "green" {
                        realColor = .green
                    } else if color == "blue" {
                        realColor = .blue
                    } else if color == "orange" {
                        realColor = .orange
                    } else {
                        realColor = .black
                    }
                    
                    let card = Phase10Card(type, color: realColor)
                    
                    DispatchQueue.main.async {
                        if let dataSource = collectionView.dataSource as? Phase10GameViewDataSource {
                            dataSource.acceptDraggedCard(card, to: destinationIndexPath.row)
                        }
                        
                        collectionView.reloadData()
                    }
                }
                
            }
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        if let itemForDrag =  (collectionView == currentHandCollectionView) ? player?.hand[indexPath.row] : player?.potentialSets[indexPath.row] {
            let itemProvider = NSItemProvider(object: "\(itemForDrag.description)" as NSItemProviderWriting)
            let dragItem = UIDragItem(itemProvider: itemProvider)
    
            return [dragItem]
        }
        
        return []
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        dropSessionDidUpdate session: UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?
    ) -> UICollectionViewDropProposal {
        if session.localDragSession != nil {
            guard session.items.count == 1 else {
                return UICollectionViewDropProposal(operation: .cancel)
            }
            
            return UICollectionViewDropProposal(operation: .move,
                                                intent: .insertAtDestinationIndexPath)
            
        } else {
            return UICollectionViewDropProposal(
                operation: .forbidden)
        }
    }
    
}
