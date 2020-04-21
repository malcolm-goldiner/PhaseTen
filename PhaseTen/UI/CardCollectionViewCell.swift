//
//  CardCollectionViewCell.swift
//  PhaseTen
//
//  Created by Malcolm Goldiner on 4/5/20.
//  Copyright © 2020 Malcolm Goldiner. All rights reserved.
//

import UIKit

class CardCollectionViewCell: UICollectionViewCell {
    
    static let reuseIdenitifer = "handCell"
    
    static let nibName = "CardCell"

    @IBOutlet weak var cardView: CardView!
    
    var card: Phase10Card? {
        didSet {
            guard let card = card else {
                return 
            }
            
            cardView.card = card 
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
