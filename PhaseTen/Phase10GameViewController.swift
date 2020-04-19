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
    
    
}

class Phase10GameViewController: UIViewController {
    
    @IBOutlet weak var scoreLabel: UILabel!
    
    @IBOutlet weak var discard: UILabel!
    
    @IBOutlet weak var topOfPileCardView: CardView!
    
    @IBOutlet weak var potentialCardSetCollectionView: UICollectionView!
    
    @IBOutlet weak var currentHandCollectionView: UICollectionView!
    
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
        
        
        _ = player?.$hand.sink(receiveValue: { [weak self] _ in
            self?.needsReload = true
        })
        
        _ = player?.$potentialSets.sink(receiveValue: { [weak self] _ in
            self?.needsReload = true
        })
    }
    
    
    private func startGame() {
        Phase10GameEngine.shared.addPlayer()
        player = Phase10GameEngine.shared.players.first
        handDataSource = Phase10GameViewDataSource(deckType: .hand, game: Phase10GameEngine.shared)
        setDataSource = Phase10GameViewDataSource(deckType: .set, game: Phase10GameEngine.shared)
        
        setupCollectionViews()
        currentHandCollectionView.reloadData()
        potentialCardSetCollectionView.reloadData()
    }
    
    private func setupCollectionViews() {
        self.currentHandCollectionView!.register(UINib(nibName: CardCollectionViewCell.nibName, bundle: Bundle.main), forCellWithReuseIdentifier: CardCollectionViewCell.reuseIdenitifer)
        
        self.potentialCardSetCollectionView.register(UINib(nibName: CardCollectionViewCell.nibName, bundle: Bundle.main), forCellWithReuseIdentifier: CardCollectionViewCell.reuseIdenitifer)
        
        currentHandCollectionView.delegate = self
        currentHandCollectionView.dataSource = handDataSource
        
        potentialCardSetCollectionView.delegate = self
        potentialCardSetCollectionView.dataSource = setDataSource
        
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
               dataSource.cardAt(indexPath) != nil else {
               return
           }
           
           dataSource.moveCard(at: indexPath.row, to: nil)
           currentHandCollectionView.reloadData()
           potentialCardSetCollectionView.reloadData()
       }
    
}

extension Phase10GameViewController: UICollectionViewDropDelegate, UICollectionViewDragDelegate {
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let dataSource = collectionView.dataSource as? Phase10GameViewDataSource else {
            return
        }
        
        let destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            destinationIndexPath = IndexPath(
                item: collectionView.numberOfItems(inSection: 0),
                section: 0)
        }
        
        let item = coordinator.items[0]
        
        switch coordinator.proposal.operation
        {
        case .move:
            print("Moving...")
            // 1
            if let sourceIndexPath = item.sourceIndexPath {
                // 2
                collectionView.performBatchUpdates({
                    dataSource.moveCard(
                        at: sourceIndexPath.item,
                        to: destinationIndexPath.item)
                    collectionView.deleteItems(at: [sourceIndexPath])
                    collectionView.insertItems(at: [destinationIndexPath])
                })
                // 3
                coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
            }
        case .copy:
            print("Copying...")
            let itemProvider = item.dragItem.itemProvider
            
            itemProvider.loadObject(ofClass: NSString.self) { string, error in
                if let string = string as? String {
                    
                    let splitCardString = string.split(separator: " ")
                    
                    let color = splitCardString.first!.description
                    if let parsedType = Int(splitCardString.last!.description),
                        let type = Phase10CardType(rawValue: parsedType) {
                        
                        let card = Phase10Card(type, color: UIColor(named: color))
                        
                        dataSource.addCard(card, atIndexPath: destinationIndexPath)
                        
                        DispatchQueue.main.async {
                            collectionView.insertItems(at: [destinationIndexPath])
                        }
                    }
                    
                }
            }
        default:
            return
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        if let itemForDrag =  collectionView == currentHandCollectionView ? player?.hand[indexPath.row] : player?.potentialSets[indexPath.row] {
            let itemProvider = NSItemProvider(object: "\(String(describing: itemForDrag.color)) \(itemForDrag.type)" as NSItemProviderWriting)
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
            
            if collectionView.hasActiveDrag {
                return UICollectionViewDropProposal(operation: .move,
                                                    intent: .insertAtDestinationIndexPath)
            } else {
                return UICollectionViewDropProposal(operation: .copy,
                                                    intent: .insertAtDestinationIndexPath)
            }
        } else {
            return UICollectionViewDropProposal(
                operation: .forbidden)
        }
    }
    
}
