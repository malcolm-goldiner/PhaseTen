//
//  Phase10GameViewController+DragandDrop.swift
//  PhaseTen
//
//  Created by Malcolm Goldiner on 4/20/20.
//  Copyright © 2020 Malcolm Goldiner. All rights reserved.
//

import UIKit

class CardDescriptor {
    
    private var desc: String
    
    private var split: [Substring] {
        return desc.split(separator: " ")
    }
    
    var color: UIColor? {
        if let colorStr = split.first {
            if colorStr == "red" {
                return .red
            } else if colorStr == "green" {
                return .green
            } else if colorStr == "blue" {
                return .blue
            } else if colorStr == "orange" {
                return .orange
            } else {
                return .black
            }
        }
        
        return nil
    }
    
    var type: Phase10CardType? {
        if let parsedType = Int(split[1].description) {
            return  Phase10CardType(rawValue: parsedType)
        }
        
        return nil
    }
    
    var deckType: DeckType? {
        if let deckStr = split.last?.description {
            switch deckStr {
            case "topSet":
                return .set(order: .top)
            case "bottomSet":
                return .set(order: .bottom)
            case "hand":
                return .hand
            case "discard":
                return .discard
            default:
                return nil
            }
        }
        
        return nil
    }
    
    var allValid: Bool {
        return deckType != nil && type != nil && color != nil
    }
    
    
    init?(desc: String) {
        self.desc = desc
        
        if desc.split(separator: " ").count != 3 || !allValid {
            return nil
        }
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
            if let string = string as? String,
                let cardDesc = CardDescriptor(desc: string), cardDesc.allValid {
                    
                let card = Phase10Card(cardDesc.type!, color: cardDesc.color!)
                    
                    DispatchQueue.main.async {
                        if let dataSource = collectionView.dataSource as? Phase10GameViewDataSource {
                            dataSource.acceptDraggedCard(card, from: cardDesc.deckType!, to: destinationIndexPath.row)
                        }
                        
                        collectionView.reloadData()
                    }
            }
        }
    }
    
    private func itemForDrag(_ collectionView: UICollectionView, at indexPath: IndexPath) -> Phase10Card? {
        if collectionView == currentHandCollectionView {
            return player?.hand[indexPath.row]
        } else if collectionView == discardPileCollectionView {
            return Phase10GameEngine.shared.discardPile.last
        } else if collectionView == bottomPotentialCardSetCollectionView {
            return player?.secondPotentialSet[indexPath.row]
        } else if collectionView == topPotentialCardSetCollectionView {
            return player?.firstPotentialSet[indexPath.row]
        }
        
        return nil
    }
    
    private func deckDescription(from collectionView: UICollectionView) -> String {
        switch collectionView {
        case topPotentialCardSetCollectionView:
            return "topSet"
        case bottomPotentialCardSetCollectionView:
            return "bottomSet"
        case currentHandCollectionView:
            return "hand"
        case discardPileCollectionView:
            return "discard"
        default:
            return ""
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        if let itemForDrag =  itemForDrag(collectionView, at: indexPath) {
            let itemProvider = NSItemProvider(object: "\(itemForDrag.description) \(deckDescription(from: collectionView))" as NSItemProviderWriting)
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
