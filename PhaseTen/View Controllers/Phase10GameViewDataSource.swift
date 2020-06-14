//
//  Phase10GameViewDataSource.swift
//  PhaseTen
//
//  Created by Malcolm Goldiner on 4/20/20.
//  Copyright © 2020 Malcolm Goldiner. All rights reserved.
//

import UIKit
import Combine

enum SetSection {
    case top
    case bottom
}

enum DeckType: Equatable {
    case hand
    case set(order: SetSection)
    case discard
}

class Phase10GameViewDataSource: NSObject, UICollectionViewDataSource {
    
    private var player: Phase10Player?
    
    var deckType: DeckType
    
    init(deckType: DeckType, game: Phase10GameEngine) {
        self.deckType = deckType
        self.player = game.players.first
    }
    
    func cardAt(_ indexPath: IndexPath) -> Phase10Card? {
        guard let player = player else {
            return nil
        }
        
        if deckType == .hand {
            return player.hand[indexPath.row]
        } else if deckType == .discard {
            return Phase10GameEngine.shared.discardPile.last
        } else if case DeckType.set(let order) = deckType {
            switch order {
            case .top:
                return player.firstPotentialSet[indexPath.row]
            case .bottom:
                return player.secondPotentialSet[indexPath.row]
            }
        }
        
        return nil 
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let player = player else {
            return 0
        }
        
        if case DeckType.set(let order) = deckType, order == .top {
            return player.firstPotentialSet.count
        } else if case DeckType.set(let order) = deckType, order == .bottom {
            return player.secondPotentialSet.count
        } else if deckType == .discard {
            return Phase10GameEngine.shared.discardPile.isEmpty ? 0 : 1
        } else {
            return player.hand.count
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
        guard let player = player else {
            return
        }
        
        switch deckType {
        case .set(let order):
            if order == .bottom {
                player.secondPotentialSet.append(card)
            } else {
                player.firstPotentialSet.append(card)
            }
        case .discard:
            Phase10GameEngine.shared.discardPile.append(card)
        case .hand:
            player.hand.append(card)
        }
    }
    
    func moveCard(at sourceIndex: Int, to destinationIndex: Int?, destinationDeckType: DeckType, sourceDeckType: DeckType) {
        guard sourceIndex != destinationIndex else { return }
        
        var destination: [Phase10Card]?
        var source: [Phase10Card]?
        
        switch destinationDeckType {
        case .hand:
            destination = player?.hand
        case .set:
            destination = player?.firstPotentialSet
        case .discard:
            destination = Phase10GameEngine.shared.discardPile
        }
        
        switch sourceDeckType {
        case .hand:
            source = player?.hand
        case .set:
            source = player?.firstPotentialSet
        case .discard:
            source = Phase10GameEngine.shared.discardPile
            
        }
        
        if let card = cardAt(IndexPath(row: sourceIndex, section: 0)) {
            destination?.append(card)
            source?.remove(at: sourceIndex)
        }
    }
    
    private func removeCard(_ card: Phase10Card, from deck: DeckType) {
        guard let player = player else {
            return
        }
        
        switch deck {
        case .hand:
            player.hand = player.hand.filter { $0 != card }
        case .set(order: let order):
            if order == .top {
                player.firstPotentialSet = player.firstPotentialSet.filter { $0 != card }
            } else if order == .bottom {
                player.secondPotentialSet = player.secondPotentialSet.filter { $0 != card }
            }
        case .discard:
            Phase10GameEngine.shared.discardPile.removeLast()
        }
    }
    
    func acceptDraggedCard(_ card: Phase10Card, from deck: DeckType, to destinationIndex: Int?) {
        guard let player = player else {
            return
        }
        
        removeCard(card, from: deck)
        
        switch deckType {
        case .set(let order):
            if order == .top {
                player.firstPotentialSet.append(card)
            } else if order == .bottom {
                player.secondPotentialSet.append(card)
            }
        case .hand:
            player.hand.append(card)
            
            if deck == .discard {
                Phase10GameEngine.shared.addActionToTurn(.pickup(card: card))
            }
            
        case .discard:
            Phase10GameEngine.shared.discardPile.append(card)
            Phase10GameEngine.shared.addActionToTurn(.discard(card: card))
        }
    }
    
}
