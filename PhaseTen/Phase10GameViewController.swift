//
//  Phase10GameViewController.swift
//  PhaseTen
//
//  Created by Malcolm Goldiner on 4/6/20.
//  Copyright © 2020 Malcolm Goldiner. All rights reserved.
//

import UIKit

class Phase10GameViewController: UIViewController {
    
    @IBOutlet weak var scoreLabel: UILabel!
    
    @IBOutlet weak var discard: UILabel!
    
    @IBOutlet weak var topOfPileCardView: CardView!
    
    @IBOutlet weak var potentialCardSetCollectionView: UICollectionView!
    
    @IBOutlet weak var currentHandCollectionView: UICollectionView!
    
    var player: Phase10Player?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.currentHandCollectionView!.register(UINib(nibName: CardCollectionViewCell.nibName, bundle: Bundle.main), forCellWithReuseIdentifier: CardCollectionViewCell.reuseIdenitifer)
        
        self.potentialCardSetCollectionView.register(UINib(nibName: CardCollectionViewCell.nibName, bundle: Bundle.main), forCellWithReuseIdentifier: CardCollectionViewCell.reuseIdenitifer)
        
        currentHandCollectionView.delegate = self
        currentHandCollectionView.dataSource = self
        
        potentialCardSetCollectionView.delegate = self
        potentialCardSetCollectionView.dataSource = self
        
        
        Phase10GameEngine.shared.addPlayer()
        player = Phase10GameEngine.shared.players.first
        currentHandCollectionView.reloadData()
        
        topOfPileCardView.card = Phase10GameEngine.shared.discardPile.last
    }
    
}

extension Phase10GameViewController: UICollectionViewDelegate, UICollectionViewDataSource {
   
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == potentialCardSetCollectionView {
            return player?.potentialSets.count ?? 0
        }
        
        return player?.hand.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CardCollectionViewCell.reuseIdenitifer, for: indexPath) as? CardCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        if collectionView == currentHandCollectionView {
               cell.card = player?.hand[indexPath.row]
        } else {
            cell.card = player?.potentialSets[indexPath.row]
        }
        
        return cell
    }
    
    
}
