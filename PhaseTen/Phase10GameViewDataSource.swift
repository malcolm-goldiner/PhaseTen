//
//  Phase10GameViewDataSource.swift
//  PhaseTen
//
//  Created by Malcolm Goldiner on 4/20/20.
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
        guard let player = player else {
            return nil
        }
        
        if deckType == .hand {
            return player.hand[indexPath.row]
        } else {
            return player.potentialSets[indexPath.row]
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let player = player else {
            return 0
        }
        
        if deckType == .set {
            return player.potentialSets.count
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
        case .set:
            player.potentialSets.append(card)
        case .hand:
            player.hand.append(card)
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
