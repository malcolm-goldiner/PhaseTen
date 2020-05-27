//
//  Phase10GameViewController+DragandDrop.swift
//  PhaseTen
//
//  Created by Malcolm Goldiner on 4/20/20.
//  Copyright © 2020 Malcolm Goldiner. All rights reserved.
//

import UIKit

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
    
    private func itemForDrag(_ collectionView: UICollectionView, at indexPath: IndexPath) -> Phase10Card? {
        if collectionView == currentHandCollectionView {
            return player?.hand[indexPath.row]
        } else if collectionView == discardPileCollectionView {
            return Phase10GameEngine.shared.discardPile.last
        } else if collectionView == potentialCardSetCollectionView {
            return player?.potentialSets[indexPath.row]
        }
        
        return nil
    }
    
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        if let itemForDrag =  itemForDrag(collectionView, at: indexPath) {
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
